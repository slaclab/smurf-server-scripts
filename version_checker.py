import numpy as np
# import matplotlib.pyplot as plt
import os
import subprocess
import yaml
import sys
import time

def command(command,errmsg):
    process = subprocess.Popen(command, shell = True,
                               stdout = subprocess.PIPE,
                               stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print(errmsg)
        return None
    else:
        return stdout.decode().split('\n')

# Start utils docker instance for version checking
docker_id = command(command='./run_version_check_utils.sh',
                    errmsg='Could not create docker, sorry :(')[0]
docker_id = docker_id[0]

# Resolve utils docker's name ; sometimes takes a few seconds for it to come up
docker_name = None
while docker_name is None:
    docker_name = command(command='docker inspect --format="{{.Name}}" '+f'{docker_id}',
                          errmsg='Could not resolve dockername, sorry :(')
    time.sleep(.1)
docker_name = docker_name[0]

slot_command = f'docker ps'
process = subprocess.Popen(slot_command, shell = True,
                           stdout = subprocess.PIPE,
                           stderr = subprocess.PIPE)
stdout, stderr = process.communicate()

def get_pysmurf_compatibility(slot_number):

#    docker_command = f'./run_version_check_utils.sh'
#    process = subprocess.Popen(docker_command, shell = True,
#                               stdout = subprocess.PIPE,
#                               stderr = subprocess.PIPE)
#
#    stdout, stderr = process.communicate()
#    if process.returncode != 0:
#        print('Could not create docker, sorry :(')
#
#    docker_lines = stdout.split(b'\n')
#    docker = docker_lines[0]
#    print(docker)
#
    versions_file_path = os.path.join(os.path.dirname(__file__), 'versions.yaml')
    versions_file = open(versions_file_path, 'r')
    versions = {}
    print('Reading versions.yml from', versions_file_path)

    try:
        versions = yaml.safe_load(versions_file)

    except yaml.YAMLError as exc:
        print("Error while parsing YAML file:")

        if hasattr(exc, 'problem_mark'):
            if exc.context != None:
                print('  parser says\n' + str(exc.problem_mark) + '\n  ' +
                      str(exc.problem) + ' ' + str(exc.context) +
                      '\nPlease correct data and retry.')
            else:
                print('  parser says\n' + str(exc.problem_mark) + '\n  ' +
                      str(exc.problem) + '\nPlease correct data and retry.')
        else:
            print("Something went wrong while parsing yaml file")

    amc_revision = versions['hardware']['amc_revision']

    hostname = 'shm-smrf-sp01'
    cba_command = f'docker exec -it {docker_name} cba_amc_init --dump {hostname}/{slot_number}'
    print(cba_command)
    process = subprocess.Popen(cba_command, shell = True,
                               stdout = subprocess.PIPE,
                               stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print('Could not get AMC slot info.')

    amc_revision_lines = stdout.split(b'\n')
    amc_revision_measured = 'Unknown'

    for line in amc_revision_lines:
        if 'Product Version' in str(line):
            print('Got AMC slot Info.')
            amc_revision_measured = line[-3:].decode('ascii')

    if amc_revision != amc_revision_measured:
        print('Incorrect AMC connected. Required', amc_revision, 'but found', amc_revision_measured)
        print('Diagnostic AMC Info:')
        print(stdout)
    else:
        print('AMC Revision OK.')

    pcie_hardware = versions['hardware']['pcie_hardware']

    pcie_hardware_command = f'cat /proc/datadev_0'
    process = subprocess.Popen(pcie_hardware_command, shell = True,
                               stdout = subprocess.PIPE,
                               stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print('Could not get PCIe Hardware info.')

    pcie_lines = stdout.split(b'\n')
    pcie_hardware_measured = 'Unknown'

    for line in pcie_lines:
        if 'DNA Value' in str(line):
            print('Got PCIe Hardware Info.')
            pcie_hardware_hex = line[-34:].decode('ascii')
            pcie_hardware_int = int(pcie_hardware_hex, 16)
            pcie_hardware_measured = str(hex(pcie_hardware_int))
            print('PCIe Hardware saved.')

#    timing_carrier = versions['hardware']['timing_carrier']
#
#    timing_amc = versions['hardware']['timing_amc']
#
#    timing_fanout_board = versions['hardware']['timing_fanout_board']
#
#    vadatech = versions['hardware']['vadatech']
#
#    shelf_manager = versions['hardware']['shelf_manager']
#
#    "Firmware"
#
#    carrier_firmware_hash = versions['firmware']['carrier_firmware_hash']
#    carrier_firmware_string = versions['firmware']['carrier_firmware_string']
#
#    amcc_command = f'amcc_dump_bsi --all {hostname}/{slot_number}'
#
#    process = subprocess.Popen(amcc_command, shell = True,
#                               stdout = subprocess.PIPE,
#                               stderr = subprocess.PIPE)
#    stdout, stderr = process.communicate()
#
#    if process.returncode != 0:
#        print('Could not get Carrier Firmware Hash.')
#        print('Could not get Carrier Firmware String')
#
#    carrier_firmware_lines = stdout.split(b'\n')
#    carrier_firmware_hash_measured = 'Unknown'
#    carrier_firmware_string_measured = 'Unknown'
#
#    for line in carrier_firmware_lines:
#        if 'GIT hash' in str(line):
#            print('Got Carrier Firmware Hash slot info.')
#            carrier_firmware_hash_measured = line[-40:].decode('ascii')
#
#    if carrier_firmware_hash != carrier_firmware_hash_measured:
#        print('Incorrect Carrier Firmware Hash connected. Required', carrier_firmware_hash, 'but found', carrier_firmware_hash_measured)
#        print('Diagnostic Carrier Info:')
#        print(stdout)
#    else:
#        print('Carrier Firmware Hash OK.')
#
#    for line in carrier_firmware_lines:
#        if 'FW bld string' in str(line):
#            print('Got Carrier Firmware String slot info.')
#            carrier_firmware_string_measured = line[-107:-1].decode('ascii')
#
#    if carrier_firmware_string != carrier_firmware_string_measured:
#        print('Incorrect Carrier Firmware String connected. Required', carrier_firmware_string, 'but found', carrier_firmware_string_measured)
#    else:
#        print('Carrier Firmware String OK.')
#
#    # Carrier Firmware Filename                                                                                                                    
#    # Technically Redundant, so skip for now                                                                                                       
#
    # PCIe Firmware                                                                                                                                

    pcie_firmware_hash = versions['firmware']['pcie_firmware_hash']
    pcie_firmware_string = versions['firmware']['pcie_firmware_string']
    pcie_firmware_version = versions['firmware']['pcie_firmware_version']

    pcie_command = f'cat /proc/datadev_0'

    process = subprocess.Popen(pcie_command, shell = True,
                               stdout = subprocess.PIPE,
                               stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print('Could not get PCIe Firmware Hash.')
        print('Could not get PCIe Firmware String.')

    pcie_firmware_lines = stdout.split(b'\n')
    pcie_firmware_hash_measured = 'Unknown'
    pcie_firmware_string_measured = 'Unknown'
    pcie_firmware_version_measured = 'Unknown'

    for line in pcie_firmware_lines:
        if 'Git Hash' in str(line):
            print('Got PCIe Firmware Hash slot info.')
            pcie_firmware_hash_measured = line[-40:].decode('ascii')

    if pcie_firmware_hash != pcie_firmware_hash_measured:
        print('Incorrect PCIe Firmware Hash connected. Required', pcie_firmware_hash, 'but found', pcie_firmware_hash_measured)
        # print('Diagnostic PCIe Info:')                                                                                                           
        # print(stdout)                                                                                                                            
    else:
        print('PCIe Firmware Hash OK.')

    for line in pcie_firmware_lines:
        if 'Build String' in str(line):
            print('Got PCIe Firmware String slot info.')
            pcie_firmware_string_measured = line[-113:].decode('ascii')

    if pcie_firmware_string != pcie_firmware_string_measured:
        print('Incorrect PCIe Firmware String connected. Required', pcie_firmware_string, 'but found', pcie_firmware_string_measured)
            # print('Diagnostic Carrier Info:')                                                                                                        
            # print(stdout)                                                                                                                            
    else:
        print('PCIe Firmware String OK.')

    for line in pcie_firmware_lines:
        if 'Firmware Version' in str(line):
            print('Got PCIe Firmware Version slot info.')
            pcie_firmware_version_hex = line[-9:-4].decode('ascii')
            pcie_firmware_version_measured = int(pcie_firmware_version_hex, 16)

    if pcie_firmware_version != pcie_firmware_version_measured:
        print('Incorrect PCIe Firmware Version connected. Required', pcie_firmware_version, 'but found', pcie_firmware_version_measured)
            # print('Diagnostic PCIe Info:')                                                                                                           
            # print(stdout)                                                                                                                            
    else:
        print('PCIe Firmware Version OK.')

#    # Timing Firmware                                                                          
#
#    timing_carrier_firmware_string = versions['firmware']['timing_carrier_firmware_string']
#    timing_carrier_string = versions['firmware']['timing_carrier_string']
#
#    # Cryostat Board Firmware                                                                                                                      
#
#    cryostat_board_firmware = versions['firmware']['cryostat_board_firmware_version']
#
#    a, b, c = self.C.get_fw_version()
#
#    if list([a, b, c]) != cryostat_board_firmware:
#        print('Incorrect Cryostat Board Firmware connected. Required', cryostat_board_firmware, 'but found [{a}, {b}, {c}]'.format(a = a, b = b, c\
# = c))
#    else:
#        print('Cryostat Board Firmware OK.')
#        # if cryostat_board_firmware[i] != cryostat_board_firmware_measured[i]:                                                                    
#        #  print('Incorrect PCIe Firmware Hash connected. Required', cryostat_board_firmware, 'but found', cryostat_board_firmware_measured)     
#        # else:                                                                                                                                    
#        #  print('Cryostat Board Firmware OK.')                                                                                                  
#
#    if [a, b, c] == [0, 0, 0]:
#        print('Cryostat Board Firmware [0, 0, 0], Cryostat Board not plugged in')
#
     # SOFTWARE                                                                                                                                     

     # PCIe Kernel Drive                                                                                                                            

    pcie_kernel_driver = versions['software']['pcie_kernel_driver_version']

    driver_command = f'cat /proc/datadev_1'
    process = subprocess.Popen(driver_command, shell = True,
                                stdout = subprocess.PIPE,
                                stderr = subprocess.PIPE)
    stdout, stderr = process.communicate()

    if process.returncode != 0:
        print('Could not get PCIe Kernel Driver Info.')

    pcie_software_lines = stdout.split(b'\n')
    pcie_kernel_driver_measured = 'Unknown'

    for line in pcie_software_lines:
        if 'Git Version' in str(line):
            print('Got PCIe Kernel Driver Info.')
            pcie_kernel_driver_measured = line[-6:].decode('ascii')

    if pcie_kernel_driver != pcie_kernel_driver_measured:
        print('Incorrect PCIe Kernel Driver connected. Required', pcie_kernel_driver, 'but found', pcie_kernel_driver_measured)
        print('Diagnostic PCIe Kernel Driver Info:')
        print(stdout)
    else:
        print('PCIe Kernel Driver OK.')

    # pysmurf Client                                                                                                                               

#    pysmurf_client = versions['software']['pysmurf_client']
#
#    pysmurf_client_measured = pysmurf.__version__
#
#    if pysmurf_client != pysmurf_client_measured[0:5]:
#        print('Incorrect pysmurf client connected. Required', pysmurf_client, 'but found', pysmurf_client_measured)
#    else:
#        print('pysmurf client OK.')
#
#    # pysmurf Server                                                                                                                               
#
#    pysmurf_server = versions['software']['pysmurf_server']
#
#    # Rogue Software                                                                                                                               
#
#    rogue_zip_filename = versions['software']['rogue_zip_filename']
#
#    epics_prefix = 'smurf_server_s{slot}'.format(slot = slot_number)
#
#    rogue_zip_filename_measured = self._caget(f'{epics_prefix}:AMCc:SmurfApplication:StartupArguments', as_string=True)
#
#    if rogue_zip_filename != rogue_zip_filename_measured[71:109]:
#        print('Incorrect rogue zip filename connected. Required', rogue_zip_filename, 'but found', rogue_zip_filename_measured[71:108])
#    else:
#        print('rogue zip filename OK.')
#
#    rogue_version = versions['software']['rogue_version']
#
#    rogue_version_measured = self._caget(f'{epics_prefix}:AMCc:RogueVersion', as_string=True)
#
#    if rogue_version != rogue_version_measured:
#        print('Incorrect rogue version connected. Required', rogue_version, 'but found', rogue_version_measured)
#    else:
#        print('rogue version OK.')
#
#    # smurf_cfg                                                                                                                                    
#
#    smurf_cfg = versions['software']['smurf_cfg_version']
#
#    smurf_cfg_measured = self._caget(f'{epics_prefix}:AMCc:SmurfApplication:SmurfVersion', as_string=True)
#
#    if smurf_cfg != smurf_cfg_measured:
#        print('Incorrect SMuRF Version connected. Required', smurf_cfg, 'but found', smurf_cfg_measured)
#    else:
#        print('SMuRF Version OK.')
#
#    # Release System                                                                                                                               
#
#    release_script = versions['software']['release_script_version']
#
#    setup_server_command = f'setup-server.sh'
#    release_script_command = f'release-docker.sh'
#
#    process = subprocess.Popen(setup_server_command, shell = True)
#
#    process = subprocess.Popen(release_script_command, shell = True,
#                               stdout = subprocess.PIPE,
#                               stderr = subprocess.PIPE)
#    stdout, stderr = process.communicate()
#
#    if process.returncode != 0:
#        print('Could not get Release Script info.')
#
#    release_script_lines = stdout.split(b'\n')
#    release_script_measured = 'Unknown'
#
#    for line in release_script_lines:
#        if 'version' in str(line):
#            print('Got Release Script Info.')
#            release_script_measured = line[-14:-20].decode('ascii')
#
#    if release_script != release_script_measured:
#        print('Incorrect Release Script connected. Required', release_script, 'but found', release_script_measured)
#        print('Diagnostic Release Script Info:')
#        print(stdout)
#    else:
#        print('Release Script OK.')
#
#    dict_file = [{'hardware' : [{'amc_revision': '%s' % amc_revision_measured}, 'rtm', 'timing_carrier', 'timing_amc', 'timing_fanout_board', 'vadatech', 'shelf_manager',  {'pcie_hardware': '%s' % pcie_hardware_measured}]}, {'firmware' : [{'carrier_firmware_hash': '%s' % carrier_firmware_hash_measured}, {'carrier_firmware_string': '%s' % carrier_firmware_string_measured}, {'pcie_firmware_hash': '%s' % pcie_firmware_hash_measured}, {'pcie_firmware_string': '%s' % pcie_firmware_string_measured}, {'pcie_firmware_version': '%s' % pcie_firmware_version_measured}, {'cryostat_board_firmware_version': '%s' % [a, b, c]}]}, {'software' : [{'pcie_kernel_driver_version': '%s' % pcie_kernel_driver_measured}, {'pysmurf_client': '%s' % pysmurf_client_measured[0:5]}, {'rogue_zip_filename': '%s' % rogue_zip_filename_measured[71:109]}, {'rogue_version': '%s' % rogue_version_measured}, {'smurf_cfg_version': '%s' % smurf_cfg_measured}]}]
#
#    path = self.output_dir
#    print(path)
#
#    with open(os.path.join(path, f'{int(time.time())}_slot{slot_number}_versions.yaml'), 'w') as file:
#        yaml.dump(dict_file, file)
#

    # check which servers are up and running                                    
    # define epics_roots as those servers                                       
    # for epics_root in epics_roots 

get_pysmurf_compatibility(4)


stop_docker = f'docker stop {docker_name}'
process = subprocess.Popen(stop_docker, shell = True,
                           stdout = subprocess.PIPE,
                           stderr = subprocess.PIPE)
