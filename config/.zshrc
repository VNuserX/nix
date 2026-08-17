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
