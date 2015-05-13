# Lab3-CHATROOM
JINWEI GU 14306748

To test the code, navigating to directory containing files and enter "ruby server.rb" firstly.
And then open the client - "ruby client.rb".

Implemented the protocol as requested. Only made a small change to the CHAT commands.
In order to send message to other users in the same chatroom, the command form would be:
CHAT:roomref(such as 0)\nJOIN_ID:join_id(such as 1)\nCLIENT_NAME:username(such as vivian)\nMESSAGE:hello\n 
<!note:last command Meesage is only \n,not like the requirement's \n\n >

Other commands are same with the requirement in lab doc.


