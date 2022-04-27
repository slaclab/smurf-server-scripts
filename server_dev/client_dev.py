import docker

def __init__(self, smurf_dict):
    self.smurf_dict = smurf_dict
    self.dc = docker.from_env()
    
def get_matching_dockers(match_str):
    container_list = self.dc.containers.list()
    container_match = []
    
    for container in container_list:
        if match_str in container.attrs['name']:
            container_match.append(container)
            
    return container_match

def stop_client(slot):
    container = self.dc.get('pysmurf_client_s' + str(slot))
    container.stop()
    
def stop_server(slot):
    container = self.dc.get('pysmurf_server_s' + str(slot))
    container.stop()
    
def stop_slot(slot):
    self.stop_client(slot)
    self.stop_server(slot)

    
