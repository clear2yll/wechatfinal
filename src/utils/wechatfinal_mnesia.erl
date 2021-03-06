%%%-------------------------------------------------------------------
%%% @author ubuntu
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 八月 2018 6:42 PM
%%%-------------------------------------------------------------------
-module(wechatfinal_mnesia).
-include_lib("stdlib/include/qlc.hrl").
-author("ubuntu").

%% API
-export([start/0,stop/0,create_table/0,init_tables/0,
         q_users/1,
         create_schema/0,
         delete_table/1,
         q_all_users/0,
         q_users_password/1,
         add_msgs/6,
         create_groups_by_name/2,
         create_groups_by_record/1,
         drop_groups/1,
         add_groups/2,
         remove_groups/2,
         q_groups/1,
         init_mnesia/0,
         q_all_groups/0,
         q_msg_by_gname/1,
         q_all_groups_by_uname/1,
         q_all_members_by_gname/1,
         update_msg/7,
         q_all_usernames/0,
         q_msg_by_sr/2,
         q_msg_page/3,
         q_msg_page2/4
         ]).

-record(users,{uname,pwd}).
-record(groups,{gname,uname}).
-record(msgs,{sender,body,receiver,msgtype,sendtimer,offline}).

start() -> mnesia:start(),mnesia:wait_for_tables([users,groups,msgs],1000),ok.

stop() -> mnesia:stop().

create_schema() ->  mnesia:create_schema([node()]).

create_table() ->
    mnesia:create_table(users, [{attributes,record_info(fields,users)},{disc_copies,[node()]},{type,set}]),
    mnesia:create_table(groups, [{attributes,record_info(fields,groups)},{disc_copies,[node()]},{type,set}]),
    mnesia:create_table(msgs, [{attributes,record_info(fields,msgs)},{disc_copies,[node()]},{type,bag}]).

init_mnesia() ->
    create_schema(),
    start(),
    create_table().
    

delete_table(Table) -> mnesia:delete_table(Table).


%% 初始化表
init_tables() ->
    mnesia:clear_table(users),
    F = fun() ->
        lists:foreach(fun mnesia:write/1, example_tables())
        end,
    mnesia:transaction(F).

%% @doc 用户表相关信息
q_users(UserName) ->
    do(qlc:q([X || X <- mnesia:table(users),X#users.uname =:= UserName])).
q_users_password(UserName) ->
    do(qlc:q([X#users.pwd || X <- mnesia:table(users),X#users.uname =:= UserName])).
q_all_users() ->
    do(qlc:q([X || X <- mnesia:table(users)])).
q_all_usernames() ->
    do(qlc:q([U || #users{uname = U} <- mnesia:table(users)])).

%% @doc 群表相关
%% -record(groups,{gname,uname}).

%% @doc 新建一个群通过名字
-spec create_groups_by_name(Gname::term(),UserName::atom()) -> term().
create_groups_by_name(Gname,UserName) ->
    Row = #groups{gname = Gname,uname = [UserName] },
    F = fun() -> mnesia:write(Row) end,
    mnesia:transaction(F).

%% @doc 新建一个群通过record
-spec create_groups_by_record(Group::term()) -> term().
create_groups_by_record(Group) ->
    F = fun() -> mnesia:write(Group) end,
    mnesia:transaction(F).

%% @doc 删除一个群
-spec drop_groups(Gname::term()) -> term().
drop_groups(Gname) ->
    Oid = {groups,Gname},
    F = fun() -> mnesia:delete(Oid) end,
    mnesia:transaction(F).

%% @doc 添加一个用户
-spec add_groups(Gname::atom(),Uname::atom()) -> term().
add_groups(Gname,Uname) ->
    %% 将群查出来
    Group = q_groups(Gname),
    Unames = Group#groups.uname,
    NewUnames1 = Unames -- [Uname],
    NewUnames2 = NewUnames1 ++ [Uname],
    NewGroup = Group#groups{uname = NewUnames2},
    %% 删除群
    %%drop_groups(Gname),
    %% 添加群
    create_groups_by_record(NewGroup).

%% @doc 移除一个用户
-spec remove_groups(Gname::atom(),Uname::atom()) -> term().
remove_groups(Gname,Uname) ->
    %% 将群查出来
    Group = q_groups(Gname),
    Unames = Group#groups.uname,
    NewUnames = Unames -- [Uname],
    NewGroup = Group#groups{uname = NewUnames},
    %% 删除群
    %%drop_groups(Gname),
    %% 添加群
    create_groups_by_record(NewGroup).

%% @doc 查询群
-spec q_groups(Gname::term()) ->term().
q_groups(Gname) ->
    [H|_] = do(qlc:q([X|| #groups{gname = G} = X <- mnesia:table(groups),G =:= Gname])),
    H.

%% @doc 查询所有群的名字
-spec q_all_groups() -> list().
q_all_groups() ->
    do(qlc:q([ G || #groups{gname = G} <- mnesia:table(groups)])).

%% @doc 根据群名字，查询群用户列表
-spec q_all_members_by_gname(Gname::atom()) -> list().
q_all_members_by_gname(Gname) ->
    [UserList] =do(qlc:q([ U || #groups{gname = G,uname = U} <- mnesia:table(groups),G =:= Gname])),
    UserList.

%% @doc 根据用户查询群列表
-spec q_all_groups_by_uname(Uname::atom()) -> list().
q_all_groups_by_uname(Uname) ->
    do(qlc:q([ G || #groups{gname = G,uname = U} <- mnesia:table(groups),lists:member(Uname,U)])).

%% -record(msgs,{sender,body,receiver,msgtype,sendtimer,offline}).
%% @doc 消息表相关

%% @doc 添加一行消息记录
-spec add_msgs(Sender::term(),Body::term(),Receiver::term(),MsgType::term(),Sendtimer::term(),OnlineUsers::term()) -> term().
add_msgs(Sender,Body,Receiver,MsgType,Sendtimer,OnlineUsers) ->
    ReceiverAtom = binary_to_atom(Receiver,utf8),
    Offline =   case MsgType of
                    private  -> [ReceiverAtom] -- OnlineUsers;
                    public -> Members = q_all_members_by_gname(ReceiverAtom),
                              Members -- OnlineUsers
                end,
    Row = #msgs{sender = Sender,body = Body,receiver = Receiver,msgtype = MsgType,sendtimer = Sendtimer,offline = Offline},
    F = fun() -> mnesia:write(Row) end,
    mnesia:transaction(F).

%% @doc 查询群聊天记录
-spec q_msg_by_gname(RoomName::term()) -> term().
q_msg_by_gname(RoomName) ->
    QList = do(qlc:q([ {S,B,R,Ty,Ti,O} || #msgs{sender = S,body = B,receiver = R,msgtype = Ty,sendtimer = Ti,offline = O} <- mnesia:table(msgs),R =:= RoomName])),
    lists:keysort(5,QList).

%% @doc 查询私聊消息
-spec q_msg_by_sr(Sender::term(),Receiver::term()) -> term().
q_msg_by_sr(Sender,Receiver) ->
    QList = do(qlc:q([ {S,B,R,Ty,Ti,O} || #msgs{sender = S,body = B,receiver = R,msgtype = Ty,sendtimer = Ti,offline = O} <- mnesia:table(msgs),(S =:= Sender andalso R =:= Receiver) or (S =:= Receiver andalso R =:= Sender)])),
    lists:keysort(5,QList).

%% @doc 更新一条消息
-spec update_msg(Sender::term(),Body::term(),Receiver::term(),MsgType::term(),Sendtimer::term(),Offline::term(),CurrUser::term()) -> term().
update_msg(Sender,Body,Receiver,MsgType,Sendtimer,Offline,CurrUser) ->
    Msg = #msgs{sender = Sender,body = Body,receiver = Receiver,msgtype = MsgType,sendtimer = Sendtimer,offline = Offline},
    NewMsg = Msg#msgs{offline = Offline -- [CurrUser]},
    F = fun() -> mnesia:delete_object(msgs,Msg,write),
                 mnesia:write(NewMsg)
                 end,
    mnesia:transaction(F).

%% @doc 分页查询群聊天记录
-spec q_msg_page(RoomName::atom(),PageSize::integer(),PageNum::integer()) -> term().
q_msg_page(RoomName,PageSize,PageNum) ->
    F = fun() ->
        Q = qlc:q([ {S,B,R,Ty,Ti,O} || #msgs{sender = S,body = B,receiver = R,msgtype = Ty,sendtimer = Ti,offline = O} <- mnesia:table(msgs),R =:= RoomName]),
        QA = qlc:e(qlc:keysort(5,Q,[{order,descending}])),
        QC = qlc:cursor(QA),
        get_page(QC,PageSize,PageNum)
        end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

%% @doc 分页查询 私聊消息
-spec q_msg_page2(Sender::term(),Receiver::term(),PageSize::term(),PageNum::term()) -> term().
q_msg_page2(Sender,Receiver,PageSize,PageNum) ->
    F = fun() ->
        Q = qlc:q([ {S,B,R,Ty,Ti,O} || #msgs{sender = S,body = B,receiver = R,msgtype = Ty,sendtimer = Ti,offline = O} <- mnesia:table(msgs),(S =:= Sender andalso R =:= Receiver) or (S =:= Receiver andalso R =:= Sender)]),
        QA = qlc:e(qlc:keysort(5,Q,[{order,descending}])),
        QC = qlc:cursor(QA),
        get_page(QC,PageSize,PageNum)
        end,
    {atomic, Val} = mnesia:transaction(F),
    Val.
    



example_tables() ->
    [
        %% The user table
        {users,<<"def">>,<<"root">>},
        {users,<<"root">>,<<"root">>},
        {users,<<"abc">>,<<"root">>},
        {users,<<"zs">>,<<"root">>},
        {users,<<"ls">>,<<"root">>},
        {users,<<"ww">>,<<"root">>}
    ].

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

%% @doc 获得第几页
%% PageSize:页面大小
%% PageNum：第几页
get_page(QC,PageSize,1) -> qlc:next_answers(QC,PageSize);
get_page(QC,PageSize,PageNum) ->
    qlc:next_answers(QC,PageSize),
    get_page(QC,PageSize,PageNum -1).
