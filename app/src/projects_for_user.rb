# Lists out all the projects that a user
# has access to based on
# * being on the same team
# * being a superuser
# * being in the approved users list for a project

# 1. #projects returns all the project in the same team
# 2. in projects_from_same_team
    # 1) super user can see everything
    # 2) project with empty project_user list, can be seen by
    #    anyone, in case all the project_user is deleted
    # 3) user in the project_user list, can see the project (creater and the user added to the project manully)

class ProjectsForUser
  def initialize(user)
    @user = user
  end

  def run
    return [] if @user.deleted
    projects.map do |project|
      next unless user_on_project?(project)
      project
    end.compact.sort_by(&:title)
  end

  private

  def projects
    @user.team.projects.active.includes(:project_users)
  end

  def user_on_project?(project)
    users = project.project_users
    return true if users.empty?
    return true if @user.super_user
    users.map(&:user_id).include? @user.id
  end
end
