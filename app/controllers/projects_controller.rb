class ProjectsController < ProjectsBaseController
  skip_before_action :verify_project_ownership, only: [:index, :create, :hook, :new]

  layout 'backstage_bare', except: [:index]

  def index
    projects = ProjectsForUser.new(current_user).run
    @facade = OpenStruct.new(
      projects: projects,
      team: current_user.team,
      unread_counts: UnactionedPromptCounter.new(projects).run
    )
    render layout: "backstage_bare"
  end

  def new

  end

  def create
    project = Project.create!(
      title: params[:name],
      team: current_user.team,
      public_feed: params[:visibility] == 'Public'
    )
    new_project_user = ProjectUser.new(project_id: project.id, user_id: current_user.id)
    project.project_users.push(new_project_user)
    new_project_user.save
    project.save

    flash[:success] = 'Project created'
    return redirect_to dashboard_path
  end

  def inbox
    @facade = Projects::InboxFacade.new(params)
  end

  def destroy
    Project.find_by(public_key: params[:public_id]).update(active: false)
    return redirect_to dashboard_path
  end

  def releases
    @facade = Projects::ReleasesFacade.new(params)
  end

  def send_release
    Resque.enqueue(
      Jobs::SendReleaseEmailForProject, params[:project_public_id]
    )
    redirect_to project_releases_path
  end
end
