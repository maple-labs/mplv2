mkdir $HOME/.ssh
touch $HOME/.ssh/id_rsa
chmod 600 $HOME/.ssh/id_rsa

git config --global url."git@github.com:".insteadOf "https://github.com/"

echo "$SSH_KEY_GLOBALS" > $HOME/.ssh/id_rsa
git submodule update --init --recursive modules/globals

git submodule update --init --recursive
