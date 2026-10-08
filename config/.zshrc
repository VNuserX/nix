# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Environment Variables & Paths
export EDITOR="nvim"
export VISUAL="nvim"
export infra="$HOME/repo/office-infrastructure/"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Safely load tenv path if installed
if command -v tenv &>/dev/null; then
  export PATH="$(tenv update-path):$PATH"
fi

# Safely load direnv hook if installed
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Safely load credentials if file exists
[[ -f "$HOME/.creds" ]] && source "$HOME/.creds"

if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# Find functions
f() {
    find . -name "*$1*"
}

ff() {
    find "$1" -name "*$2*" 2>/dev/null
}


# Git Aliases
alias gdiff='$HOME/working/scripts/git_tag_commit_diff_deep.sh'
alias gsync='git stash && git pull && git stash pop'
alias gtag='git --no-pager tag -n $(git describe --tags `git rev-list --tags --max-count=1`)'
alias gcommit='git --no-pager log -1 -p apps-versions.tf | tee > /tmp/diff; python ~/working/python/git_commit.py'
alias glog='git --no-pager log --format=%B -n 1'
alias gshort='git log -1 --format="%h"'

# Kubernetes Aliases & Helpers
alias k='kubectl'
alias kgp='kubectl get pods'
alias deckube='/bin/ksd'
alias busybox='kubectl run -i --tty busybox --image=alpine -- /bin/sh'
alias containers_count_nodes='$HOME/working/scripts/count_container_on_nodes'
alias cluster_health='$HOME/working/scripts/cluster_health'

alias not_ready="kubectl get pods --no-headers | grep -v 'Running\|Completed' | awk '{print \"kubectl delete pod \"\$1}'"
alias not_job_completed="kubectl get pods -A --field-selector=status.phase=Succeeded -o json | jq '.items[] | select(.metadata.ownerReferences[].kind != \"Job\") |\"kubectl delete pod \(.metadata.name) -n \(.metadata.namespace)\"' | cut -d'\"' -f2"
alias not_running_pods="kubectl get pods -A --no-headers | grep -v 'Running\|Completed' | awk '{print \"kubectl delete pod -n \"\$1\" \"\$2 \" #reason \"\$4}'"
alias not_running_pods_status="kubectl get pods -A --no-headers | grep -v 'Running\|Completed' | awk '{print \"kubectl get pod -n \"\$1\" \"\$2 \" #reason \"\$4}'"
alias rolebindings="kubectl get rolebindings,clusterrolebindings -A -o custom-columns='SERVICE_ACCOUNTS:subjects[?(@.kind==\"ServiceAccount\")].name,NAMESPACE:metadata.namespace,ROLE:roleRef.name,NAME:metadata.name,KIND:kind'"


# Terraform Aliases
alias tf='terraform'
alias tfa='terraform apply'
alias tfao='terraform apply "plan.tfplan"'
alias tfc='terraform console'
alias tfd='terraform destroy'
alias tff='terraform fmt'
alias tfg='terraform graph'
alias tfim='terraform import'
alias tfin='terraform init'
alias tfo='terraform output'
alias tfp='terraform plan'
alias tfpo='terraform plan --out=plan.tfplan'
alias tfpr='terraform providers'
alias tfr='terraform refresh'
alias tfsh='terraform show'
alias tft='terraform taint'
alias tfut='terraform untaint'
alias tfv='terraform validate'
alias tfw='terraform workspace'
alias tfs='terraform state'
alias tffu='terraform force-unlock'
alias tfwst='terraform workspace select'
alias tfwsw='terraform workspace show'
alias tfssw='terraform state show'
alias tfwde='terraform workspace delete'
alias tfwls='terraform workspace list'
alias tfsls='terraform state list'
alias tfwnw='terraform workspace new'
alias tfsmv='terraform state mv'
alias tfspl='terraform state pull'
alias tfsph='terraform state push'
alias tfsrm='terraform state rm'
alias tfinu='terraform init -upgrade'


# Storage Helper Function
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

        cat <<EOF | kubectl apply -f -
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
EOF

        echo "Waiting for pod to be ready..."
        kubectl wait --for=condition=Ready pod/${POD_NAME} --timeout=60s

        echo "Entering pod and opening /mnt/store..."
        kubectl exec -it ${POD_NAME} -- sh -c "cd /mnt/store && exec sh"
    )
}

garage() {
  kubectl exec -c garage -it garage-0 -- ./garage "$@"
}

anonymize_logs() {
  sed -E \
    -e 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]+)?/****/g' \
    -e 's/(key )[A-Za-z0-9_-]+/\1****/g' \
    -e 's/(uploadId=)[A-Za-z0-9_-]+/\1****/g' \
    -e 's/[a-f0-9]{40}/****/g' \
    "${1:-/dev/stdin}"
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

tftarget() {
  local file="$1"
  local keyword="$2"
  local action="${3:-print}"  # Defaults to 'print'

  if [[ -z "$file" || -z "$keyword" ]]; then
    echo "Usage: tftarget <file> <keyword> [print|plan|apply]"
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found."
    return 1
  fi

  local -a raw_targets targets

  # 1. Parse Terraform plan output (# resource.address)
  raw_targets+=(${(f)"$(grep -E '^[[:space:]]*#[[:space:]]+' "$file" | awk '{print $2}')"})

  # 2. Parse HCL resource blocks (resource "type" "name" {)
  raw_targets+=(${(f)"$(grep -E '^[[:space:]]*resource[[:space:]]+' "$file" | awk -F'"' '{print $2 "." $4}')"})

  # 3. Parse direct address lines (e.g. kubernetes_namespace_v1.zorro)
  raw_targets+=(${(f)"$(grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+' "$file")"})

  # Filter by keyword (case-insensitive), deduplicate
  targets=(${(u)${(f)"$(printf '%s\n' "${raw_targets[@]}" | grep -i -- "$keyword" | sort -u)"}})

  if (( ${#targets} == 0 || ${#targets[1]} == 0 )); then
    echo "No targets found matching '$keyword' in '$file'."
    return 1
  fi

  local -a target_flags
  for t in "${targets[@]}"; do
    target_flags+=("-target=$t")
  done

  case "$action" in
    print)
      # Prints the command string ready to copy or pipe
      echo "terraform plan ${target_flags[*]}"
      ;;
    plan|apply)
      echo "Executing: terraform $action ${target_flags[*]}"
      echo ""
      terraform "$action" "${target_flags[@]}"
      ;;
    *)
      echo "Invalid action '$action'. Allowed values: print (default), plan, apply."
      return 1
      ;;
  esac
}
