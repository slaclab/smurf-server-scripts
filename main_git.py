from git import Repo
import git.exc
import os

def is_repo(path):
    """
    Ideally this is some generic way to pull the various SMuRF
    repositories.
    """
    
    if not os.path.isdir(path):
        return False
    
    try:
        _ = Repo(path).git_dir
    except git.exc.InvalidGitRepositoryError:
        return False

    return True

def is_repo_verbose(path):
    if is_repo(path):
        repo = Repo(path)
        current_commit = repo.commit('HEAD').hexsha
        branch = str(repo.active_branch)
        message = repo.commit('HEAD').message
        message_short = message[:25] if len(message) > 25 else message
        
        print(f'Found repo in {path}, its current branch is {branch}, current commit is {current_commit}, current message {message_short}...')
        return True

    else:
        print(f'No repo found in {path}.')
        return False
