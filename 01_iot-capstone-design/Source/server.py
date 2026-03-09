import socket

HOST = '192.168.0.14' 
# Server IP or Hostname
PORT = 12345 
# Pick an open Port (1000+ recommended), must match the client sport
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print('Socket created')

#managing error exception
try:
	s.bind((HOST, PORT))
except socket.error:
	print('Bind failed ')

s.listen(5)
print('Socket awaiting messages')
(conn, addr) = s.accept()
print('Connected')

# awaiting for message
while True:
	data = conn.recv(1024)
	print('I sent a message back in response to: ',end='')
	print(data)
	reply = ''
	sdata = str(data, 'utf-8')
	# process your message
	if sdata == 'Hello':
		reply = 'Hi, back!'
	elif sdata == 'This is important':
		reply = 'OK, I have done the important thing you have asked me!'
	#and so on and on until...
	elif sdata == 'quit':
		conn.send('Terminating')
		break
	else:
		reply = 'Unknown command'

	# Sending reply
	conn.send(bytes('aaaaaa',encoding='utf-8'))
conn.close()
