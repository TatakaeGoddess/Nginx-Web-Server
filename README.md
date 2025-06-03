Пошаговая инструкция по созданию защищенного Web-сервера Nginx на базе ОС Ubuntu Server 24.04.1 LTS

1. Создаем виртуальную машину на базе ОС Ubuntu Server 24.04.1 LTS в ПО Oracle VM Virtual Box с характеристиками:
ОЗУ: 4 Гб
ЦП: 4 ядра 
HDD: 30 Гб
	
3. Обновляем список репозиториев:
apt-get update
	
	4. Обновляем установленное ПО ОС:
apt-get upgrate -y
	
	5. Устанавливаем Web-сервер Ngnix:
	apt-get install ngnix
	
	6. Устанавливаем openssh-sftp-server:
apt-get install  openssh-sftp-server -y
	
	7. Узнаем IP-адрес ВМ:
ip address 
	
	8. Подключаемся через MobaXTerm к машине по SSH-протоколу. 
	
	9. Создаем пару открытого SSL-сертификата и закрытого ключа: 
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt 
		При запросе значения Common name вводим IP адрес.
		
	10. Прописываем расположение файлов ключа и SSL-сертификата для Nginx создав конфигурационный файл:
nano /etc/nginx/snippets/self-signed.conf
		Прописываем в self-signed.conf пути к SSL-сертификату (значение ssl_certificate) и закрытому ключу (значение ssl_certificate_key): 
			ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt; 
			ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
			
	11. Прописываем настройки SSL для Nginx в конфигурационном файле:
	nano /etc/nginx/snippets/ssl-params.conf
		Прописала настройки:
			ssl_protocols TLSv1.2;
			ssl_prefer_server_ciphers on;
			ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
			ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
			ssl_session_timeout  10m;
			ssl_session_cache shared:SSL:10m;
			ssl_session_tickets off; # Requires nginx >= 1.5.9
			ssl_stapling on; # Requires nginx >= 1.3.7
			ssl_stapling_verify on; # Requires nginx => 1.3.7
			resolver 8.8.8.8 8.8.4.4 valid=300s;
			resolver_timeout 5s;
			# Disable strict transport security for now. You can uncomment the following
			# line if you understand the implications.
			# add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
			add_header X-Frame-Options DENY;
			add_header X-Content-Type-Options nosniff;
			add_header X-XSS-Protection "1; mode=block";
			
	12. Создаем резервную копию текущей конфигурации Nginx:
 cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bck
	
	13. Настраиваем  поддержку SSL в текущей конфигурации Nginx:
 nano /etc/nginx/sites-available/default
		Прописываем настройки для прослушивания 443 порта (HTTPS), указываем пути к конфигурационным файлам с SSL-сертификатом/закрытым ключом и настройками SSL:
			server {
			    listen 443 ssl;
			    listen [::]:443 ssl;
			    include snippets/self-signed.conf;
			    include snippets/ssl-params.conf;
			
			root /var/www/html;
			        index index.nginx-debian.html;
			
			  server_name _;
			
			  location / {
			                try_files $uri $uri/ =404;
			        }
			}
		Прописываем переадресацию запросов с 80 порта (HTTP) на 443 порт (HTTPS):
			server {
			    listen 80;
			    listen [::]:80;
			
			    server_name 192.168.43.108;
			
			    return 302 https://$server_name$request_uri;
			}
			
	14. Проверяем наличие брандмауэра (файрволла) в ОС запросив статус профилей:
	ufw status
	
	15.  Проверяем внесенные изменения в текущей конфигурации Nginx на ошибки: 
	nginx -t
	
	16. Перезагружаем Nginx для применения изменений:
	systemctl restart nginx 
	
	17. Проверяем корректность введенных изменений:
		В браузере пероходим по адресу https://192.168.43.108 . Ожидаемый результат - открывается стартовая страница Nginx, отображается знак "Защищено".
		В браузере переходим по адресу  http://192.168.43.108 . Ожидаемы результат - произошла переадресация на  https://192.168.43.108 ,  открывается стартовая страница Nginx, отображается знак "Защищено".
		Проверяем сертификат:
			Нажимаем на знак "Защищено" -> Переходим в пункт "Подключение защищено" -> Переходим в пункт "Действительный сертификат" -> Проверяем значения полей "Общее имя", "Дата выдачи", "Срок действия".
			
	18. Перенастраиваем дефолтные порты http с 80 на 8080 и https с 443 на 8443:
	В /etc/nginx/sites-avaliable/default изменила:
	server {
	        listen 8443 ssl;
	        listen [::]:8443 ssl;
	        include snippets/self-signed.conf;
	        include snippets/ssl-params.conf;
	
	        root /var/www/html;
	        index index.nginx-debian.html;
	
	        server_name _;
	
	        location / {
	                    try_files $uri $uri/ =404;
	        }
	}
	
	server {
	        listen 8080;
	        listen [::]:8080;
	
	        server_name 192.168.43.108;
	
	        return 302 https://$server_name:8443$request_uri;
	}
	
	19. Перезагружаем Nginx для применения изменений:
	systemctl restart nginx 
	
	20. Настраиваем ротацию логов access.log и error.log Nginx раз в час с архивацией, логи старше 5 часов будут удаляться:
	Создаем конфигурационный файл /etc/logrotate.d/nginx.conf :
	nano /etc/logrotate.d/nginx.conf
Прописываем правила ротации:
		compress
		
		/var/log/nginx/access.log {
		hourly
		rotate 5
		noolddir
		}
		
		/var/log/nginx/error.log {
		hourly
		rotate 5
		noolddir
		}
	21. Добавляем logrotate в crontab:
	Вносим изменения в crontab:
	crontab -e
	Прописываем: 
	0 * * * * /etc/cron.daily/logrotate
	
	22. Настраиваем автостарт веб-сервера Nginx:
systemctl enable nginx
	
	23. Настраиваем модуль статистики веб-сервера Nginx, к которому разрешаем доступ только с localhost:
Проверяем, включен-ли модуль статистики в установленную сборку веб-сервера Nginx:
nginx -V 2>&1 | grep -o with-http_stub_status_module
	Включаем модуль статистики веб-сервера Nginx в /etc/nginx/sites-available/default:
server {
		        listen 8443 ssl;
		        listen [::]:8443 ssl;
		        include snippets/self-signed.conf;
		        include snippets/ssl-params.conf;
		
		        root /var/www/html;
		        index index.nginx-debian.html;
		
		        server_name _;
		
		        location / {
		                    try_files $uri $uri/ =404;
		        }
		        location = /basic_status {
		                                  stub_status;
		                                  allow 192.168.43.108;
		                                  deny all;
		        }
		}
		
	24. Перезагружаем Nginx для применения изменений:
	systemctl restart nginx 
	
	25. Проверяем доступность модуля статистики веб-сервера Nginx:
	Переходим по адресу https://192.168.43.108:8443/basic_status
	
	26. Пишем скрипт, который показывает количество обращений с кодом 200 к index.html:
Создаем файл sh-скрипта:
nano /home/darya/code_200_from_access_log_nginx.sh
	Прописываем в него конструкцию, отбирающую из лога access.log ответы с кодом 200:
#!/bin/bash
	cat /var/log/nginx/access.log | awk '{print $9}' | grep -c 200
	exit 0
	Далаем права на исполнение скрипту:
	chmod +x /home/darya/code_200_from_access_log_nginx.sh
	Проверяем работоспособность скрипта:
/home/darya/code_200_from_access_log_nginx.sh
![image](https://github.com/user-attachments/assets/c6dbcd95-858b-45b1-b34e-d07442500806)

