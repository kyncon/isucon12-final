# TODO: APP_HOMEとAPP_DIRECTORYなど、埋める
APP_HOME:=/home/isucon/webapp
APP_DIRECTORY:=$(APP_HOME)/go
APP_BUILD_COMMAND:=go build -o isuconquest
SYSTEMCTL_APP:=isuconquest.go.service

# TODO: nginxのファイルの場所を指定する
NGINX_CONF:=$(APP_HOME)/nginx/nginx.conf
NGINX_APP_CONF:=$(APP_HOME)/nginx/isuconquest.conf
NGINX_LOG:=/var/log/nginx/access.log
NGINX_ERR_LOG:=/var/log/nginx/error.log
ALP_FORMAT:=/image/\w+,/posts/\d+,/@\w+

# TODO: mysqlのコンフィグファイルの場所を指定する
MYSQL_CONF:=$(APP_HOME)/mysql/mysqld.cnf
MYSQL_LOG:=/var/log/mysql/mysql-slow.log

# TODO: IPを埋める
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
SERVER1_IP:=133.152.6.169
SERVER2_IP:=133.152.6.170
SERVER3_IP:=133.152.6.171
SERVER4_IP:=133.152.6.172
SERVER5_IP:=133.152.6.173
SERVER1:=isucon@$(SERVER1_IP)
SERVER2:=isucon@$(SERVER2_IP)
SERVER3:=isucon@$(SERVER3_IP)
SERVER4:=isucon@$(SERVER3_IP)
SERVER5:=isucon@$(SERVER3_IP)

SLACK_CHANNEL=isucon11-log
SLACKCAT_RAW_CMD=slackcat -c $(SLACK_CHANNEL)

SSH_COMMAND=ssh -t

all: build

# .PHONY: bench
# bench:
# 	benchmarker/bin/benchmarker -t "http://$(SERVER1_IP)" -u benchmarker/userdata

.PHONY: build build-server1 build-server2 build-server3 build-app build-nginx build-mysql
build:
	$(SSH_COMMAND) $(SERVER1) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server1 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER2) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server2 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER3) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server3 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER4) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server4 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER5) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server5 BRANCH:=$(BRANCH)'

# Set app, mysql and nginx.
build-server1: build-app build-nginx
build-server2: stop-app build-mysql
build-server3: stop-app
build-server4: stop-app
build-server5: stop-app

DATE=$(shell date '+%T')

build-app:
	sudo systemctl stop $(SYSTEMCTL_APP)
	cd $(APP_DIRECTORY) && $(APP_BUILD_COMMAND)
	sudo systemctl restart $(SYSTEMCTL_APP)
	sudo systemctl enable $(SYSTEMCTL_APP)

stop-app:
	sudo systemctl stop $(SYSTEMCTL_APP)
	sudo systemctl disable $(SYSTEMCTL_APP)

build-nginx:
	-sudo mv $(NGINX_LOG) /tmp/nginx_access_$(DATE).log
	-sudo mv $(NGINX_ERR_LOG) /tmp/nginx_error_$(DATE).log
	sudo cp $(NGINX_CONF) /etc/nginx/
	sudo cp $(NGINX_APP_CONF) /etc/nginx/sites-enabled/
	sudo systemctl restart nginx.service

build-mysql:
	-sudo mv $(MYSQL_LOG) /tmp/mysql_log_$(DATE).log
	sudo cp $(MYSQL_CONF) /etc/mysql/mysql.conf.d/
	sudo systemctl restart mysql.service


.PHONY: log log-server1 log-server2 log-server3 log-nginx log-nginx-diff log-mysql log-app echo-branch
log:
	$(SSH_COMMAND) $(SERVER1) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server1'
	$(SSH_COMMAND) $(SERVER2) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server2'
	$(SSH_COMMAND) $(SERVER3) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server3'
	$(SSH_COMMAND) $(SERVER4) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server4'
	$(SSH_COMMAND) $(SERVER5) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server5'

# Send log to slack
# Set log-nginx or log-mysql.
log-server1: echo-branch log-app log-nginx log-nginx-diff
log-server2: log-mysql log-mysql-diff
log-server3:
log-server4:
log-server5:

echo-branch:
	git rev-parse --abbrev-ref HEAD | $(SLACKCAT_RAW_CMD) -tee --stream

log-app:
	sudo systemctl status $(SYSTEMCTL_APP) | $(SLACKCAT_RAW_CMD)

ALP_OPTIONS=--sort=sum -r

log-nginx:
	sudo cat $(NGINX_LOG) | alp ltsv -m "$(ALP_FORMAT)" $(ALP_OPTIONS) | $(SLACKCAT_RAW_CMD)
	-[ -s $(NGINX_ERR_LOG) ] && sudo cat $(NGINX_ERR_LOG) | $(SLACKCAT_RAW_CMD)

DEFAULT_BRANCH=$(shell git remote show origin | sed -n '/HEAD branch/s/.*: //p')
LAST_MERGED_BRANCH=$(shell git log --first-parent origin/$(DEFAULT_BRANCH) --oneline --merges --pretty=format:"%s" -1 | sed -e "s;Merge pull request \#[0-9]\{1,\} from kyncon/;;g" -e "s;/;-;g")
log-nginx-diff:
	sudo cat $(NGINX_LOG) | alp ltsv $(ALP_OPTIONS) --dump /tmp/nginx_alp.yaml
	-sudo alp diff /tmp/nginx_alp_$(LAST_MERGED_BRANCH)_latest.yaml /tmp/nginx_alp.yaml $(ALP_OPTIONS) -o count,2xx,4xx,5xx,method,uri,min,max,sum,avg,p90 | $(SLACKCAT_RAW_CMD)
	-sudo mv /tmp/nginx_alp.yaml /tmp/nginx_alp_$(shell echo $(BRANCH) | sed -e "s@/@-@g")_latest.yaml

SLP_OPTIONS=--bundle-values --bundle-where-in --sort=sum-query-time -r

log-mysql:
	sudo cat $(MYSQL_LOG) | slp $(SLP_OPTIONS) | $(SLACKCAT_RAW_CMD)

log-mysql-diff:
	sudo cat $(MYSQL_LOG) | slp $(SLP_OPTIONS) --dump /tmp/mysql_slp.yaml
	-sudo slp diff /tmp/mysql_slp_$(LAST_MERGED_BRANCH)_latest.yaml /tmp/mysql_slp.yaml --show-footers $(SLP_OPTIONS) | $(SLACKCAT_RAW_CMD)
	-sudo mv /tmp/mysql_slp.yaml /tmp/mysql_slp_$(shell echo $(BRANCH) | sed -e "s@/@-@g")_latest.yaml


.PHONY: check
check:
	$(SSH_COMMAND) $(SERVER1) journalctl -ex -u $(SYSTEMCTL_APP)
