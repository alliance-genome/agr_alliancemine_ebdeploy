
eb-init:
	eb init --region us-east-1 -p Docker alliancemine

eb-create:
	eb create stage-alliancemine --region=us-east-1 --cname="stage-alliancemine" --elb-type classic --timeout 30

