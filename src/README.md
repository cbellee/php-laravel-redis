# About

This repo is to test Azure Redis slowness.

In the `.env` file, There's a password, which you will have to get from me. Please replace `<AskJoe>`

To run, please go to ubuntu (or whichever flavor) terminal and type this command  
`php artisan app:test-redis`

The above command will execute the php file in `/app/Console/Commands/TestRedis.php`. This file will queue 10000 jobs, whilst reporting how long it takes for each 1000 jobs queued. 

Sample output:
```
~/src/workshop/joe-test/joe-redis $ php artisan app:test-redis
Test started at 2024-04-19 04:58:28
Jobs queued: 0 at 2024-04-19 04:58:28
Jobs queued: 1000 at 2024-04-19 04:59:22
Jobs queued: 2000 at 2024-04-19 05:00:18
Jobs queued: 3000 at 2024-04-19 05:01:11
Jobs queued: 4000 at 2024-04-19 05:02:06
Jobs queued: 5000 at 2024-04-19 05:03:01
Jobs queued: 6000 at 2024-04-19 05:03:55
Jobs queued: 7000 at 2024-04-19 05:04:49
Jobs queued: 8000 at 2024-04-19 05:05:43
Jobs queued: 9000 at 2024-04-19 05:06:38
Test concluded at 2024-04-19 05:07:33
```

As per the above sample output, we are seeing that it takes about 1 minute to queue/dispatch every 1000 jobs. In AWS, it takes a split second to dispatch 50K jobs.

## Build
- PHP 8.1
- Laravel 10

Snippets on how to install php and composer. 
```
# echo "--> PHP PPA"
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

echo "--> PHP 8.1"
sudo apt install -y php8.1
php -v

echo "--> Composer"
sudo apt-get install php8.1-cli php8.1-mbstring zip php8.1-curl php8.1-xml php8.1-gd php8.1-zip php8.1-intl php8.1-mysql
curl -sS https://getcomposer.org/installer -o composer-setup.php
ONLINE_HASH="$(curl -sS https://composer.github.io/installer.sig)"
echo "$ONLINE_HASH composer-setup.php" | sha384sum --check
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
composer -V

```