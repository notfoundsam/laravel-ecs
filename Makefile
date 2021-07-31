UID=''
RHOST=''
OS=''
DCF='docker-compose.yml'

AWS_PROFILE='notfoundsam'

# Detect OS
UNAME= $(shell uname -s)

ifeq ($(UNAME), Linux)
	UID=$(id -u):$(id -g)
	RHOST=$(hostname -I | awk '{print $1}')
	OS='linux'
endif
ifeq ($(UNAME), Darwin)
	UID=''
	RHOST='host.docker.internal'
	OS='mac'
endif

ALL: info
info:
	@echo "[web]   http://localhost:9010"
	@echo "[bsync] http://localhost:9011"
	@echo "[email] http://localhost:1010"
	@echo "[db]    http://localhost:3310"
aws-setup:
	pip3 install --upgrade awscli
	aws configure --profile $(AWS_PROFILE)
build:
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) build
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer composer run-script post-root-package-install
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer composer run-script post-create-project-cmd
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm node yarn
up:
	CURRENT_UID=$(value UID) REMOTE_HOST=$(value RHOST) docker-compose -f $(DCF) up -d
	make info
stop:
	docker-compose -f $(DCF) stop
migrate:
	docker-compose -f $(DCF) exec php-fpm php artisan migrate
rollback:
	docker-compose -f $(DCF) exec php-fpm php artisan migrate:rollback
composer-autoload:
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer composer dump-autoload
composer-update:
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer composer update
refresh:
	docker-compose -f $(DCF) exec php-fpm php artisan migrate:refresh --seed
truncate:
	docker-compose -f $(DCF) exec php-fpm php artisan migrate:refresh
console:
	docker-compose -f $(DCF) exec php-fpm php artisan tinker
clear:
	docker-compose -f $(DCF) exec php-fpm php artisan cache:clear
	docker-compose -f $(DCF) exec php-fpm php artisan route:cache
route:
	docker-compose -f $(DCF) exec php-fpm php artisan route:list
sh-php:
	docker-compose -f $(DCF) exec php-fpm sh
watch:
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm node yarn
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm node yarn watch
deploy-prod:
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm composer
	CURRENT_UID=$(value UID) docker-compose -f $(DCF) run --rm node yarn prod
	./aws/release-production.sh $(OS)
rollback-db-prod:
	./aws/rollback-db-production.sh $(OS)
