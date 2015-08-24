current_directory = $(pwd)
#
if [ -d $HOME/code/dot-files ]; then
  cd $HOME/code/dot-files
#   git pull origin master
fi

rsync -av bash/ $HOME
rsync -av git/ $HOME

exec $SHELL
source ~/.bash_profile
cd $current_directory
