# ビルドして、サービスのリスタートを行う
# リスタートを行わないと反映されないので注意
.PHONY: build
build:
	cd /home/isucon/webapp/go; \
	go build -o isucondition main.go; \
	sudo systemctl restart isucondition.go.service;

# pprofのデータをwebビューで見る
# サーバー上で sudo apt install graphvizが必要
.PHONY: pprof
pprof:
	go tool pprof -http=0.0.0.0:8080 /home/isucon/webapp/go/isucondition http://localhost:6060/debug/pprof/profile

# mysql
MYSQL_HOST="192.168.0.12"
MYSQL_PORT=3306
MYSQL_USER=isucon
MYSQL_DBNAME=isucondition
MYSQL_PASS=isucon

MYSQL=mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
SLOW_LOG=/tmp/slow-query.log

# slow-query-logを取る設定にする
# DBを再起動すると設定はリセットされる
.PHONY: slow-on
slow-on:
	-sudo rm $(SLOW_LOG)
	sudo systemctl restart mysql
	$(MYSQL) -e "set global slow_query_log_file = '$(SLOW_LOG)'; set global long_query_time = 0.001; set global slow_query_log = ON;"

.PHONY: slow-off
slow-off:
	$(MYSQL) -e "set global slow_query_log = OFF;"

# mysqldumpslowを使ってslow query logを出力
# オプションは合計時間ソート
# このコマンドは2台目から叩かないと意味がない
.PHONY: slow-show
slow-show:
	sudo mysqldumpslow -s t $(SLOW_LOG) | head -n 20

# nginx
# scp-nginx:
# 	ssh isucon11-qualify-1 "sudo dd of=/etc/nginx/nginx.conf" < ./etc/nginx/nginx.conf
# 	ssh isucon11-qualify-1 "sudo dd of=/etc/nginx/sites-available/isucondition.conf" < ./etc/nginx/sites-available/isucondition.conf

nginx-reload:
	ssh isucon11-qualify-1 "sudo systemctl reload nginx.service"

nginx-rotate:
	ssh isucon11-qualify-1 sudo sh -c 'test -f /var/log/nginx/access.log && mv -f /var/log/nginx/access.log /var/log/nginx/access.log.old || true'
	ssh isucon11-qualify-1 'sudo kill -USR1 `cat /var/run/nginx.pid`'

# deploy-nginx: scp-nginx nginx-reload

# alp
ALPSORT=sum
ALPM="/api/isu/.+/icon,/api/isu/.+/graph,/api/isu/.+/condition,/api/isu/[-a-z0-9]+,/api/condition/[-a-z0-9]+,/api/catalog/.+,/api/condition\?,/isu/........-....-.+"
OUTFORMAT=count,method,uri,min,max,sum,avg,p99
# .PHONY: alp
# alp:
# 	sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
alp:
	ssh isucon11-qualify-1 "sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q"

# .PHONY: alpsave
# alpsave:
# 	sudo alp ltsv --file=/var/log/nginx/access.log --pos /tmp/alp.pos --dump /tmp/alp.dump --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q

# .PHONY: alpload
# alpload:
# 	sudo alp ltsv --load /tmp/alp.dump --sort $(ALPSORT) --reverse -o count,method,uri,min,max,sum,avg,p99 -q

# deploy
deploy:
	ssh isucon11-qualify-1 "cd /home/isucon && \
		git checkout . && \
		git fetch && \
		git checkout $(BRANCH) && \
		git reset --hard origin/$(BRANCH) && \
		cd /home/isucon"
