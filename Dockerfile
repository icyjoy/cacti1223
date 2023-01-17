FROM ubuntu:20.04

RUN apt update -y
RUN apt install apache2 -y
RUN systemctl start apache2
RUN systemctl enable apache2

EXPOSE 80

RUN apt install mariadb-server mariadb-client

COPY 50-server.cnf /etc/mysql/mariadb.conf.d/
RUN chown -R root:root /etc/mysql/mariadb.conf.d/50-server.cnf

RUN apt install libapache2-mod-php php-mysql php-xml php-gd php-snmp php-json php-intl php-mbstring php-ldap php-gmp -y
COPY php.ini /etc/php/7.4/apache2/
RUN chown -R root:root /etc/php/7.4/apache2/php.ini

RUN apt install rrdtool snmp snmpd snmp-mibs-downloader libsnmp-dev

mysql -uroot -e "CREATE DATABASE cactidb;"
mysql -uroot -e "GRANT ALL ON cactidb.* TO ‘cacti_user’@’localhost’ IDENTIFIED BY ‘P@ssw0rd123’;"
mysql -uroot -e "FLUSH PRIVILEGES;"

COPY cacti /var/www/html/
RUN chown -R www-data:www-data /var/www/html/cacti
mysql -uroot -p cactidb < /var/www/html/cacti/cacti.sql
mysql -uroot -p mysql < /usr/share/mysql/mysql_test_data_timezone.sql
mysql -uroot -e "GRANT SELECT on mysql.time_zone_name to cacti_user@localhost;"
mysql -uroot -e "FLUSH PRIVILEGES;"

COPY config.php /var/www/html/cacti/include/
RUN chown -R www-data:www-data /var/www/html/cacti

COPY cacti.conf /etc/apache2/sites-available/
RUN chown root:root /etc/apache2/sites-available/cacti.conf

RUN systemctl restart apache2
