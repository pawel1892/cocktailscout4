#!/bin/bash
echo "++++++++++ Running rake db:drop ++++++++++"
rake db:drop
echo "++++++++++ Running rake db:create++++++++++"
rake db:create
echo "++++++++++ Running rake db:migrate++++++++++"
rake db:migrate
echo "++++++++++ Running rake db:seed++++++++++"
rake db:seed
