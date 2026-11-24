# --- Kubernetes Helpers ---

attach-storage() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a PVC name."
        echo "Usage: attach-storage <name-of-pvc>"
        return 1
    fi

    (
        PVC_NAME=$1
        POD_NAME="custom-pvc-pod-${PVC_NAME}"

        trap "echo -e '\nCleaning up: Deleting pod ${POD_NAME}...'; kubectl delete pod ${POD_NAME} --wait=false" EXIT INT TERM

        echo "🚀 Creating pod '${POD_NAME}' for PVC '${PVC_NAME}'..."

        cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
spec:
  volumes:
- name: local-storage
    persistentVolumeClaim:
      claimName: ${PVC_NAME}
  containers:
- name: custom-pvc-pod
    image: busybox
    command:
- sh
- -c
- 'sleep 100000'
    volumeMounts:
- mountPath: /mnt/store
      name: local-storage
YAML

        echo "Waiting for pod to be ready..."
        kubectl wait --for=condition=Ready pod/${POD_NAME} --timeout=60s

        echo "Entering pod and opening /mnt/store..."
        kubectl exec -it ${POD_NAME} -- sh -c "cd /mnt/store && exec sh"
    )
}

kdebug() {
  if [[ -z "$1" ]]; then
    echo "Usage: kdebug <pod-name> [target-container] [debug-image] [-- <command...>]"
    echo "Examples:"
    echo "  kdebug garage-0"
    echo "  kdebug garage-0 -- ls -la /proc/1/root"
    echo "  kdebug garage-0 garage busybox -- ps aux"
    return 1
  fi

  local POD_NAME="$1"
  shift

  local TARGET_CONTAINER=""
  local DEBUG_IMAGE="busybox"
  local CUSTOM_CMD=()

  if [[ -n "$1" && "$1" != "--" ]]; then
    TARGET_CONTAINER="$1"
    shift
  fi

  if [[ -n "$1" && "$1" != "--" ]]; then
    DEBUG_IMAGE="$1"
    shift
  fi

  if [[ "$1" == "--" ]]; then
    shift
  fi

  if [[ $# -gt 0 ]]; then
    CUSTOM_CMD=("$@")
  fi

  if [[ -z "$TARGET_CONTAINER" ]]; then
    TARGET_CONTAINER=$(kubectl get pod "$POD_NAME" -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)
  fi

  local INIT_CMD='
    PID=$(ps aux | awk '\''!/PID|sh|bash|ps|grep/ {print $1; exit}'\'')
    PID=${PID:-1}
    export TARGET_PID=$PID
    echo "==> Target Process PID: $TARGET_PID"
    if [ -d "/proc/$TARGET_PID/root" ]; then
      cd "/proc/$TARGET_PID/root"
      echo "==> Switched working directory to: $(pwd)"
    fi
    exec /bin/sh
  '
  local CMD=(kubectl debug -it "$POD_NAME" --image="$DEBUG_IMAGE")

  if [[ -n "$TARGET_CONTAINER" ]]; then
    CMD+=(--target="$TARGET_CONTAINER")
  fi

  if [[ ${#CUSTOM_CMD[@]} -gt 0 ]]; then
    CMD+=(-- "${CUSTOM_CMD[@]}")
  else
    CMD+=(-- /bin/sh -c "$INIT_CMD")
  fi

  echo "==> Triggered Command:"
  echo "    ${CMD[*]}"
  echo ""

  "${CMD[@]}"
}

garage() {
  kubectl exec -c garage -it garage-0 -- ./garage "$@"
}

# --- Terraform Helpers ---

tftarget() {
	local file=""
	local keyword=""
	local action="print"
	local select_all=0

	for arg in "$@"; do
		case "$arg" in
			(-a|--all)
				select_all=1
				;;
			(*)
				if [[ -z "$file" ]]; then
					file="$arg"
				elif [[ "$arg" == "print" || "$arg" == "plan" || "$arg" == "apply" ]]; then
					action="$arg"
				elif [[ -z "$keyword" ]]; then
					keyword="$arg"
				else
					echo "Error: Unexpected argument '$arg'."
					echo "Usage: tftarget <file> <keyword|--all|all> [print|plan|apply]"
					return 1
				fi
				;;
		esac
	done

	if [[ "$keyword" == "all" || "$keyword" == "*" ]]; then
		select_all=1
	fi

	if [[ -z "$file" || ( $select_all -eq 0 && -z "$keyword" ) ]]; then
		echo "Usage: tftarget <file> <keyword|--all|all> [print|plan|apply]"
		return 1
	fi

	if [[ ! -f "$file" ]]; then
		echo "Error: File '$file' not found."
		return 1
	fi

	local clean_content
	clean_content="$(sed -E $'s/\x1b\\[[0-9;]*[a-zA-Z]//g' "$file")"

	local -a raw_targets targets

	raw_targets+=(${(f)"$(printf '%s\n' "$clean_content" | grep -E '^[[:space:]]*#[[:space:]]+[a-zA-Z0-9_.-]+(\[[^]]+\])?[[:space:]]+(will|has|must|is)' | awk '{print $2}')"})

	if (( ${#raw_targets} == 0 || ${#raw_targets[1]} == 0 )); then
		raw_targets+=(${(f)"$(printf '%s\n' "$clean_content" | grep -E '^[[:space:]]*resource[[:space:]]+"' | awk -F'"' '{print $2 "." $4}')"})
		raw_targets+=(${(f)"$(printf '%s\n' "$clean_content" | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_.-]+(\[[^]]+\])?$')"})
	fi

	if (( ${#raw_targets} > 0 && ${#raw_targets[1]} > 0 )); then
		if (( select_all )); then
			targets=(${(u)${(f)"$(printf '%s\n' "${raw_targets[@]}" | sort -u)"}})
		else
			targets=(${(u)${(f)"$(printf '%s\n' "${raw_targets[@]}" | grep -i -- "$keyword" | sort -u)"}})
		fi
	fi

	if (( ${#targets} == 0 || ${#targets[1]} == 0 )); then
		echo "No targets found${keyword:+ matching '$keyword'} in '$file'."
		return 1
	fi

	local -a target_flags
	for t in "${targets[@]}"; do
		target_flags+=("-target=$t")
	done

	case "$action" in
		(print)
			echo "terraform plan ${target_flags[*]}"
			;;
		(plan | apply)
			echo "Executing: terraform $action ${target_flags[*]}"
			echo ""
			terraform "$action" "${target_flags[@]}"
			;;
	esac
}

# --- General & Log Helpers ---

anonymize_logs() {
  sed -E \
    -e 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]+)?/****/g' \
    -e 's/(key )[A-Za-z0-9_-]+/\1****/g' \
    -e 's/(uploadId=)[A-Za-z0-9_-]+/\1****/g' \
    -e 's/[a-f0-9]{40}/****/g' \
    "${1:-/dev/stdin}"
}

qfind() {
  local file="$HOME/working/scripts/favorit_commads"
  if [ -z "$1" ]; then
    cat "$file" | fzf
  else
    grep -i "$1" "$file" | fzf
  fi
}

rep() {
    local delay=3
    [[ "$1" =~ ^[0-9]+s?$ ]] && delay="${1%s}" && shift

    while true; do
        "$@"
        sleep "${delay}s"
    done
}

# Find functions
f() {
    find . -name "*$1*"
}

ff() {
    find "$1" -name "*$2*" 2>/dev/null
}

