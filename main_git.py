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

def get_repo(repo_url, path, version):
    repo = Repo.clone_from(repo_url, path, branch = version)
    return repo

def get_repo_if_nonexistant(repo_url, version, path):
    if not is_repo(path):
        pwd = os.environ['PWD']
        print(f'No repo in {path}, cloning {repo_url} at version {version} to {path}. Current dir is {pwd}.')
        repo = get_repo(repo_url, path, version)
        repo.head.reference = r.create_head('main')
        
    else:
        repo = Repo(path)
        current_commit = repo.commit('HEAD').hexsha
        branch = str(repo.active_branch)
        message = repo.commit('HEAD').message
        message_short = message[:25] if len(message) > 25 else message
        
        print(f'Found repo in {path}, its current branch is {branch}, current commit is {current_commit}, current message {message_short}...')
