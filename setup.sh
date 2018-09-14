 #!/bin/bash

current_directory=`pwd`
script_directory=`dirname ${BASH_SOURCE}`

if [ -d $script_directory ]; then
  cd $script_directory
  git pull origin master --quiet
fi

rsync -avq shell/ $HOME
rsync -avq git/ $HOME

