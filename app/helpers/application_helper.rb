module ApplicationHelper
	require 'octokit'
	require 'httparty'
	require 'net/http'
	require 'json'

	def get_the_job_done(id)
		json_obj = []
		dashboard = Dashboard.find id
		dashboard.dashboard_widgets.each do |dash_wid|
			json_obj << JSON.parse(dash_wid.to_json).compact
		end		
		json_obj.each do |obj|
			case (Widget.find obj["widget_id"]).name
			when "Github-Open-PR"
				github_open_pr_job(obj)
			when "Github-Closed-PRR"
				github_closed_pr_job(obj)
			when "GPA"
				gpa(obj)
			# when "Github-Status"
			# 	github_status(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Github-Last-10-Commits"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "To-Do-list"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Assign-to-QA"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Sprint-remaning-day"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Sprint-progress"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "No of open-issues"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "GPA"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Test-coverage"
			# 	github_open_pr_job(obj)
			# when (Widget.find json_obj.first["widget_id"]).name = "Build-test"
			# 	github_open_pr_job(obj)
			end
		end
	end

	def github_open_pr_job(obj)
		Dashing.scheduler.every '10s', :first_in => 0 do |job|
		  client = Octokit::Client.new(:access_token => obj["access_token"])
		  my_organization = obj["organization_name"]
		  repos = client.organization_repositories(my_organization).map { |repo| repo.name }

		  open_pull_requests = repos.inject([]) { |pulls, repo|
		      if repo==obj["repo_name"]
		    		client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
		      	pulls.push({
		        	title: pull.title,
		        	repo: repo,
		        	updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
		        	creator: "@" + pull.user.login,
		        })
		      end
		    end
		    pulls
		  }
		  p open_pull_requests
		  Dashing.send_event('open_pr', { header: "Open Pull Requests", pulls: open_pull_requests })
		end
	end

	def github_closed_pr_job(obj)
		Dashing.scheduler.every '10s', :first_in => 0 do |job|
		  client = Octokit::Client.new(:access_token => obj["access_token"])
		  my_organization = obj["organization_name"]
		  repos = client.organization_repositories(my_organization).map { |repo| repo.name }

		  closed_pull_requests = repos.inject([]) { |pulls, repo|
		    client.pull_requests("#{my_organization}/#{repo}", :state => 'close').each do |pull|
		      if repo==obj["repo_name"]
		      pulls.push({
		        title: pull.title,
		        repo: repo,
		        updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
		        creator: "@" + pull.user.login,
		        })
		      end
		    end
		    pulls
		  }

		  Dashing.send_event('closed_pr', { header: "Closed Pull Requests", pulls: closed_pull_requests })
		end
	end

	# def github_status(obj)
	# 	GITHUB_STATUS_TO_TRAFFIC_LIGHT_MAP = {
	# 	  'good' => 'green',
	# 	  'minor' => 'amber',
	# 	  'major' => 'red'
	# 	}
	# 	GITHUB_STATUS_URI = obj["github_url"]

	# 	Dashing.scheduler.every '10s', :first_in => 0 do
	# 	  response = HTTParty.get(GITHUB_STATUS_URI)
	# 	  data = {
	# 	    status: GITHUB_STATUS_TO_TRAFFIC_LIGHT_MAP[response["status"]],
	# 	    message: response["body"]
	# 	  }
	# 	  Dashing.send_event('github_status', data)
	# 	end
	# end

	def gpa(obj)
		Dashing.scheduler.every '10s', :first_in => 0 do |job|
		  # repo_id = "5406f507e30ba0542305e4e3"
		  # repo_id = "550134e1695680688f009211"
		  # api_token = "f21310bb41e60a6890ee27343c865c3dc4784434ab7d32a6590ca637344451e1"
		  # api_token = "255887c05d5a64ea167e4d3455f63d8f71574536"
	    uri = URI.parse("https://codeclimate.com/api/repos/#{obj['code_repo_id']}")
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.use_ssl = true
	    request = Net::HTTP::Get.new(uri.request_uri)
	    request.set_form_data({api_token: obj['code_api_token']})
	    response = http.request(request)
	    stats = JSON.parse(response.body)
	    current_gpa = stats['last_snapshot']['gpa'].to_f
	    app_name = stats['name']
	    covered_percent = stats['last_snapshot']['covered_percent'].to_f
	    last_gpa = stats['previous_snapshot']['gpa'].to_f
	    Dashing.send_event("code-climate", {current: current_gpa, last: last_gpa, name: app_name, percent_covered: covered_percent })
		end		
	end

	def github_last_10_commits
		
	end

	def method_name
		
	end

	def method_name
		
	end
end
