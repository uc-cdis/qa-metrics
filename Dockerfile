FROM frvi/dashing

ADD widgets /widgets
ADD dashboards /dashboards
ADD jobs /jobs

CMD ["/run.sh"]
