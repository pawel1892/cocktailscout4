-- new
id	int(11)	NO	PRI	NULL	auto_increment
forum_thread_id	int(11)	YES		NULL
user_id	int(11)	YES		NULL
ip	varchar(255)	YES		NULL
content	text	YES		NULL
deleted	tinyint(1)	YES		NULL
last_editor_id	int(11)	YES		NULL
created_at	datetime	YES		NULL
updated_at	datetime	YES		NULL

-- old
post_id	bigint(11)	NO	PRI	NULL	auto_increment
post_thread_id	bigint(10)	NO	MUL	0
post_author_id	int(8)	NO		0
post_time	bigint(14)	NO		0
post_time_last_edit	bigint(14)	NO		0
post_user_ip	varchar(15)	NO
post_content	text	NO		NULL
post_category	int(2)	NO		0
post_deleted	tinyint(4)	NO		0
post_edit_user_id	int(11)	YES		NULL