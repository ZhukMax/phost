#!/bin/bash

# Keys for script
while [ 1 ] ; do 
   if [ "$1" = "--blank" ] ; then 
      PROJECT="b" 
   elif [ "$1" = "-b" ] ; then 
      PROJECT="b"
   elif [ "$1" = "--new" ] ; then 
      PROJECT="n" 
   elif [ "$1" = "-n" ] ; then 
      PROJECT="n"
   elif [ "$1" = "--exists" ] ; then 
      PROJECT="x" 
   elif [ "$1" = "-x" ] ; then 
      PROJECT="x"
   elif [ "$1" = "--postgresql" ] ; then
      DBVERS=2
   elif [ "$1" = "-p" ] ; then
      DBVERS=2
   elif [ "$1" = "--mysql" ] ; then
      DBVERS=1
   elif [ "$1" = "-m" ] ; then
      DBVERS=1
   elif [ "$1" = "--delete" ] ; then
      DELETE=1
   elif [ -z "$1" ] ; then 
      break
   else 
      echo "Error: unknown key" 1>&2 
      exit 1 
   fi 
   shift 
done

if [ -z "$DBVERS" ] ; then
	if hash mysql 2>/dev/null; then
		DBVERS=1
	else
		DBVERS=2
	fi
fi

if [ -z "$DELETE" ] ; then

	echo "Enter project name for site:"
	read USERNAME

	echo "Enter domain:"
	read DOMAIN

	if [ -z "$PROJECT" ] ; then
		echo "Blank (b), new (n) or exists (x) project?"
		echo "default - blank (b):"
		read PROJECT
	fi

	if [ "$PROJECT" == n ] || [ "$PROJECT" == new ]
	then
		cd /var/www
		phalcon create-project $USERNAME
	elif [ "$PROJECT" == x ] || [ "$PROJECT" == exists ]
	then
		mkdir /var/www/$USERNAME
		cd /var/www/$USERNAME
		echo "Enter url to your git-repository:"
		read REPO
		git clone $REPO
		cd ~
	else
		mkdir /var/www/$USERNAME
	fi

	mkdir /var/www/$USERNAME/tmp
	mkdir /var/www/$USERNAME/logs
	chmod -R 755 /var/www/$USERNAME/
	chown www-data:www-data /var/www/$USERNAME

	echo "Creating vhost file"
	echo "
	server {
	    listen      80;
	    server_name $DOMAIN www.$DOMAIN;
	    root        /var/www/$USERNAME/public;
		  access_log	/var/www/$USERNAME/logs/access.log;
		  error_log	/var/www/$USERNAME/logs/error.log;
	    index       index.php;

	    location / {
		try_files \$uri \$uri/ /index.php?_url=\$uri&\$args;
	    }

	    location ~ \.php {
		fastcgi_pass  unix:/var/run/php/php7.0-fpm.sock;
		fastcgi_index /index.php;

		include fastcgi_params;
		fastcgi_split_path_info       ^(.+\.php)(/.+)\$;
		fastcgi_param PATH_INFO       \$fastcgi_path_info;
		fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
	    }

	    location ~ /\.ht {
		deny all;
	    }
	}
	" > /etc/nginx/sites-available/$USERNAME.conf
	ln -s /etc/nginx/sites-available/$USERNAME.conf /etc/nginx/sites-enabled/$USERNAME.conf

	service nginx restart
	service php7.0-fpm restart

	#if [ -z "$DBVERS" ] ; then
	#	echo "MySQL[1] or PostgreSQL[2]"
	#	echo "(default 1):"
	#	read DBVERS
	#fi

	echo "Enter DataBase root password:"
	read -s ROOTPASS

	echo "Enter password for new DB:"
	read -s SQLPASS

	echo "Creating database"

	Q1="CREATE DATABASE IF NOT EXISTS $USERNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;;"
	Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $USERNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$SQLPASS';"
	Q3="FLUSH PRIVILEGES;"
	SQL="${Q1}${Q2}${Q3}"

	if [[ "$DBVERS" = 2 ]] ; then
		psql -username=root --password=$ROOTPASS -e "$SQL"
	else
		mysql -uroot --password=$ROOTPASS -e "$SQL"
	fi

else

	echo "Enter project name for delete:"
	read USERNAME

	echo "Enter DataBase root password:"
	read -s ROOTPASS
	
	if [[ "$DBVERS" = 2 ]] ; then
		psql -uroot --password=$ROOTPASS -e "DROP USER $USERNAME@localhost"
		psql -uroot --password=$ROOTPASS -e "DROP DATABASE $USERNAME"
	else
		mysql -uroot --password=$ROOTPASS -e "DROP USER $USERNAME@localhost"
		mysql -uroot --password=$ROOTPASS -e "DROP DATABASE $USERNAME"
	fi
	
	rm -f /etc/nginx/sites-enabled/$USERNAME.conf
	rm -f /etc/nginx/sites-available/$USERNAME.conf
	rm -rf /var/www/$USERNAME

	service nginx restart
	service php7.0-fpm restart

fi
