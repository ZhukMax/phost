#!/bin/bash 

echo "Enter username for site:"
read USERNAME

echo "Enter domain"
read DOMAIN

mkdir /var/www/$USERNAME
mkdir /var/www/$USERNAME/tmp
mkdir /var/www/$USERNAME/logs
mkdir /var/www/$USERNAME/public
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

echo "Creating php7.0-fpm config"
 
echo "[www]
 
listen = /var/run/php/php7.0-fpm.sock
listen.mode = 0666
chdir = /var/www/$USERNAME
 
php_admin_value[upload_tmp_dir] = /var/www/$USERNAME/tmp
php_admin_value[soap.wsdl_cache_dir] = /var/www/$USERNAME/tmp
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M
php_admin_value[open_basedir] = /var/www/$USERNAME/
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source,stream_socket_client,stream_set_write_buffer,stream_socket_sendto,highlight_file,com_load_typelib
php_admin_value[cgi.fix_pathinfo] = 0
php_admin_value[date.timezone] = Europe/London
php_admin_value[session.gc_probability] = 1
php_admin_value[session.gc_divisor] = 100
 
 
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 4
" > /etc/php/7.0/fpm/pool.d/$USERNAME.conf

service nginx restart
service php7.0-fpm restart

echo "Enter MySQL root password:"
read ROOTPASS

echo "Enter password for new DB:"
read MYSQLPASS

echo "Creating database"

Q1="CREATE DATABASE IF NOT EXISTS $USERNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $USERNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$MYSQLPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
	
mysql -uroot --password=$ROOTPASS -e "$SQL"
