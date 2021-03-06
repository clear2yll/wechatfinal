%% -*- coding: utf-8 -*-
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.2.1

-ifndef(wechatfinal_cmd_pb).
-define(wechatfinal_cmd_pb, true).

-define(wechatfinal_cmd_pb_gpb_version, "4.2.1").

-ifndef('CHAT_PB_H').
-define('CHAT_PB_H', true).
-record(chat,
        {sender                 :: iodata(),        % = 1
         body                   :: iodata(),        % = 2
         receiver               :: iodata(),        % = 3
         timer                  :: integer() | undefined, % = 4, 32 bits
         display                :: iodata(),        % = 5
         type                   :: 'private' | 'public' | integer() | undefined, % = 6, enum pattern
         unread                 :: iodata() | undefined % = 7
        }).
-endif.

-ifndef('ONLINE_PB_H').
-define('ONLINE_PB_H', true).
-record(online,
        {type                   :: 'private' | 'public' | integer(), % = 1, enum pattern
         body                   :: iodata() | undefined, % = 2
         online = []            :: [iodata()] | undefined, % = 3
         offline = []           :: [iodata()] | undefined % = 4
        }).
-endif.

-ifndef('ROOM_PB_H').
-define('ROOM_PB_H', true).
-record(room,
        {type                   :: 'create' | 'add' | 'remove' | 'drop' | 'flush' | 'history' | integer(), % = 1, enum room_type
         rname                  :: iodata() | undefined, % = 2
         body                   :: iodata() | undefined, % = 3
         history = []           :: [wechatfinal_cmd_pb:chat()] | undefined % = 4
        }).
-endif.

-ifndef('SYSTEM_PB_H').
-define('SYSTEM_PB_H', true).
-record(system,
        {type                   :: 'private' | 'public' | integer(), % = 1, enum pattern
         receiver               :: iodata(),        % = 2
         body                   :: iodata()         % = 3
        }).
-endif.

-ifndef('HISTORY_PB_H').
-define('HISTORY_PB_H', true).
-record(history,
        {sender                 :: iodata() | undefined, % = 1
         receiver               :: iodata() | undefined, % = 2
         history = []           :: [wechatfinal_cmd_pb:chat()] | undefined, % = 3
         pageSize               :: integer() | undefined, % = 4, 32 bits
         pageNum                :: integer() | undefined % = 5, 32 bits
        }).
-endif.

-ifndef('DATA_PB_H').
-define('DATA_PB_H', true).
-record(data,
        {chat                   :: wechatfinal_cmd_pb:chat() | undefined, % = 1
         online                 :: wechatfinal_cmd_pb:online() | undefined, % = 2
         room                   :: wechatfinal_cmd_pb:room() | undefined, % = 3
         system                 :: wechatfinal_cmd_pb:system() | undefined, % = 4
         history                :: wechatfinal_cmd_pb:history() | undefined % = 5
        }).
-endif.

-ifndef('MSG_PB_H').
-define('MSG_PB_H', true).
-record(msg,
        {type                   :: 'chat' | 'online' | 'room' | 'system' | 'history' | integer(), % = 1, enum cmd
         data                   :: wechatfinal_cmd_pb:data() % = 2
        }).
-endif.

-endif.
