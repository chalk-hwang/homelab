#!/usr/bin/env bash
set -e

CONFIG_DIR="/home/vscode/.config"
VS_CODE_USER="vscode"
ASDF_VERSION="2.34.0"
TOOLS="cilium flux helm helmfile k9s kustomize"

# Ensure correct ownership of .config directory
sudo chown -R ${VS_CODE_USER}:${VS_CODE_USER} ${CONFIG_DIR}

# Add hooks into fish
tee ${CONFIG_DIR}/fish/conf.d/hooks.fish >/dev/null <<EOF
if status is-interactive
    direnv hook fish | source
    starship init fish | source
end
EOF

# Add direnv whitelist for the workspace directory
mkdir -p ${CONFIG_DIR}/direnv
tee ${CONFIG_DIR}/direnv/direnv.toml >/dev/null <<EOF
[whitelist]
prefix = [ "/workspaces" ]
EOF

# Setup direnv with asdf for bash and fish shells
asdf direnv setup --shell bash --version ${ASDF_VERSION}
asdf direnv setup --shell fish --version ${ASDF_VERSION}

# Change to workspace directory
cd /workspaces/home-ops

if [ -f .tool-versions ]; then
    # Add the asdf plugin by extracting the first field (tool name) from the .tool-versions content
    cut -d' ' -f1 .tool-versions | xargs -I {} asdf plugin add {} || true
else
    echo ".tool-versions 파일을 찾을 수 없습니다."
fi

# Install direnv and set local environment
asdf direnv install
asdf direnv local

# Generate fish completions for various tools
for tool in ${TOOLS}; do
    ${tool} completion fish >${CONFIG_DIR}/fish/completions/"${tool}".fish
done
gh completion --shell fish >${CONFIG_DIR}/fish/completions/gh.fish
stern --completion fish >${CONFIG_DIR}/fish/completions/stern.fish
yq shell-completion fish >${CONFIG_DIR}/fish/completions/yq.fish

# Add aliases into fish
tee ${CONFIG_DIR}/fish/conf.d/aliases.fish >/dev/null <<EOF
alias ls lsd
alias kubectl kubecolor
alias k kubectl
EOF

# Custom fish prompt
tee ${CONFIG_DIR}/fish/conf.d/fish_greeting.fish >/dev/null <<EOF
set fish_greeting
EOF

# Set ownership vscode .config directory to the vscode user
sudo chown -R ${VS_CODE_USER}:${VS_CODE_USER} ${CONFIG_DIR}

# Set up Starship with custom preset
starship preset nerd-font-symbols > ${CONFIG_DIR}/starship.toml

# Setup fisher plugin manager for fish and install plugins
/usr/bin/fish -c "
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fisher install decors/fish-colored-man
fisher install edc/bass
fisher install jorgebucaran/autopair.fish
fisher install nickeb96/puffer-fish
fisher install PatrickF1/fzf.fish
"

task workstation:venv