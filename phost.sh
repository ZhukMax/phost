#!/bin/bash 

echo "Enter username for site:"
read USERNAME
 
echo "Enter domain"
read DOMAIN

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
