# cse534-lb-p4
This project is for CSE 534, depicting use of P4 switches in load balancing.

Steps for running the code

1. upload all the below files/folders in your fabric directory
    1.  notebook.ipynb 
    2. scripts folder
    3. install_bmv2.sh file
    4. main.p4
    5. server_load_monitoring.py
    6. switch_webhook.py
    7. table-rules.sh 
2. Once all the files are uploded, run the notebook.ipynb file
3. Open the switch terminal and start the switch using the commnad "sudo /home/ubuntu/simple_switch_hp -i 0@enp9s0 -i 1@enp11s0 -i 2@enp8s0 main.json &". Run the command without the quotes.
4. Execute the cell with comments "#upload match action rules directly from the rules file" in the notebook.ipynb file
5. Open the server terminals and run the python webserver using sudo python3 cpu_intensive_task.py
6. Open another switch terminal and run the  command sudo python3 switch_webhook.py
7. Open the meas-node terminal and run the command sudo python3 server_load_monitoring.py. Change the username and pasword in the server_load_monitoring.poy file as folows. The creds can be obtained by running the cell with the comment "#### CREDENTIALS FOR ACCESSING THE PROMETHUES API" in the notebook.ipynb
    auth_user = <ht_user>
    auth_pwd = <ht_password>
8. Open the client node terminal  and start issuing client requests using apache bench using the command 
    ab -n 1000 -s 9999 -c 4 http://192.168.1.1:80/heavy-load
    Above command will issue 1000 requests with conncurrency level 4 for the heavy-compute task

    ab -n 1000 -s 9999 -c 4 http://192.168.1.1:80/light-load
    Above command will issue 1000 requests with conncurrency level 4 for the light-compute task