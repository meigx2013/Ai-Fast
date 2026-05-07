CREATE TABLE `agentorbit_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '稳定 GUID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置显示名称',
  `server_url` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'AgentOrbit Server URL',
  `auth_mode` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'client-key' COMMENT '认证模式: client-key | none',
  `client_key` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '客户端静态 Key（加密存储）',
  `client_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '客户端标识',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1-活跃, 0-停用',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agentorbit_configs_guid` (`guid`),
  UNIQUE KEY `uk_agentorbit_configs_name` (`name`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AgentOrbit 连接配置表';

CREATE TABLE `agentorbit_instances` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '稳定 GUID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户 ID (FK: users.id)',
  `instance_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'AgentOrbit 实例 ID（外部标识）',
  `instance_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '实例显示名称',
  `is_default` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1-用户默认实例, 0-非默认',
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT '状态: active | stopped | error',
  `deployment_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'remote' COMMENT '部署类型: remote | local | embedded',
  `agentorbit_config_id` bigint unsigned DEFAULT NULL COMMENT '关联配置 ID (FK: agentorbit_configs.id)',
  `config_snapshot` json DEFAULT NULL COMMENT '创建时的配置快照（JSON）',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agentorbit_instances_guid` (`guid`),
  UNIQUE KEY `uk_agentorbit_instances_instance_id` (`instance_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_is_default` (`is_default`),
  KEY `idx_status` (`status`),
  KEY `idx_config_id` (`agentorbit_config_id`),
  CONSTRAINT `fk_agentorbit_instances_config` FOREIGN KEY (`agentorbit_config_id`) REFERENCES `agentorbit_configs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AgentOrbit 数字分身实例表';

CREATE TABLE `asset_collections` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `repository_id` bigint NOT NULL,
  `collection_uid` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Stable UID used in routes, e.g. core-banking',
  `project_uid` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Stable Project UID used in routes',
  `date_created` datetime NOT NULL COMMENT 'Created time (UTC)',
  `created_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Creator name',
  `date_updated` datetime NOT NULL COMMENT 'Last updated time (UTC)',
  `updated_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Last updater name',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT 'active / inactive',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

CREATE TABLE `asset_command_scenario` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置类型 (toolset|spec|mcp|skill)',
  `registry_id` bigint NOT NULL COMMENT 'asset_registry_info表主键',
  `command` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '命令标识符',
  `scenario` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '场景描述',
  `md_content` text COLLATE utf8mb4_unicode_ci COMMENT '命令的Markdown内容',
  `date_created` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `date_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `updated_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_registry_command` (`config_type`,`registry_id`,`command`),
  KEY `idx_asset_command_scenario_registry_id` (`registry_id`),
  KEY `idx_asset_command_scenario_config_type` (`config_type`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='命令场景关联表';

CREATE TABLE `asset_registry_info` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `registry_level` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '注册级别（server | project）',
  `registry_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '注册ID',
  `config_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置类型（toolset|spec|mcp|skill）',
  `affiliated_organization` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属组织（project_collections 表的guid）',
  `affiliated_project` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属项目（projects表的guid）',
  `guid` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '全局唯一标识',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '注册名称',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT '描述',
  `version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '版本',
  `download_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '下载地址',
  `path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '路径',
  `entry_point` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '入口点',
  `commands` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '安装命令',
  `scenario` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '场景',
  `is_share` tinyint DEFAULT '0' COMMENT '是否共享：0-否，1-是',
  `date_created` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `date_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `updated_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`),
  KEY `idx_asset_registry_project_config_type` (`affiliated_project`,`config_type`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资源注册信息表';

CREATE TABLE `asset_repositories` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `asset_level` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '关联级别 org | project',
  `config_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '配置类型：toolset_repo | spec_repo',
  `repository_source_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gitlab' COMMENT '仓库源类型：gitlab / github',
  `base_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库源 Base URL，如 https://gitlab.example.com',
  `repository_auth_method` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'private' COMMENT '仓库授权方式:public | private',
  `token` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '访问 Token（API 返回时脱敏）',
  `repository_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库名称或路径，如 group/repo',
  `default_branch` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '默认分支，如 main',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active' COMMENT '状态：Active / Deactive',
  `date_created` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
  `created_by` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `date_updated` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
  `updated_by` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_project_repositories_config_type` (`config_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='项目仓库表（支持多配置类型）';

CREATE TABLE `bank_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `iam_login_no` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '来自上游 data.name',
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bank_users_iam_login_no` (`iam_login_no`),
  UNIQUE KEY `uk_bank_users_email` (`email`),
  KEY `idx_bank_users_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `config_settings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Stable GUID',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Display name',
  `uname` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique identifier (e.g. asdm-pipeline-config)',
  `level` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'server | collection | project | user',
  `collection_id` int unsigned DEFAULT NULL COMMENT 'Scope: collection (FK project_collections.id)',
  `project_id` int unsigned DEFAULT NULL COMMENT 'Scope: project',
  `user_id` int unsigned DEFAULT NULL COMMENT 'Scope: user',
  `value` json NOT NULL COMMENT 'JSON object: config key-value',
  `operator_scope` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'all-admin' COMMENT 'Operator scope: all-admin | whitelist-admin',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_settings_guid` (`guid`),
  UNIQUE KEY `uk_config_settings_uname` (`uname`),
  KEY `ix_config_settings_level` (`level`),
  KEY `ix_config_settings_collection_id` (`collection_id`),
  KEY `ix_config_settings_project_id` (`project_id`),
  KEY `ix_config_settings_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `feature_flags` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键 ID',
  `flag_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '开关唯一标识',
  `flag_value` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'false' COMMENT '开关值（字符串存储，布尔场景使用 true/false）',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '开关说明（描述控制功能与生效效果）',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `updated_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `date_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `date_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_feature_flags_flag_key` (`flag_key`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务端功能开关配置表';

CREATE TABLE `flyway_schema_history` (
  `installed_rank` int NOT NULL,
  `version` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `script` varchar(1000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` int DEFAULT NULL,
  `installed_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execution_time` int NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`),
  KEY `flyway_schema_history_s_idx` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `global_repositories` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '展示名称',
  `uname` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '唯一标识',
  `setting_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'server' COMMENT '一级类型：server | pipeline',
  `pipeline_type` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '二级类型（setting_type=pipeline）',
  `server_type` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '服务端二级类型（setting_type=server）：github | jenkins',
  `repository_source_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'github' COMMENT '仓库源类型：gitlab / github / custom',
  `base_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库源 Base URL',
  `repository_auth_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'token' COMMENT '鉴权方式：none | token',
  `token` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '访问 Token',
  `repository_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '仓库名称或路径，如 owner/repo',
  `workflow_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '流水线 workflow id（pipeline 类型）',
  `default_branch` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '默认分支，如 main',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active' COMMENT '状态：Active / Deactive / Removed',
  `date_created` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
  `created_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `date_updated` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
  `updated_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_global_repositories_uname` (`uname`),
  KEY `idx_global_repositories_setting_type` (`setting_type`),
  KEY `idx_global_repositories_pipeline_type` (`pipeline_type`),
  KEY `idx_global_repositories_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='组织级全局仓库/流水线配置表';

CREATE TABLE `library_context_item_database` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `context_id` bigint NOT NULL,
  `context_item_id` bigint NOT NULL,
  `table_schema` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Database/schema name',
  `table_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Table name',
  `ddl` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CREATE TABLE DDL statement',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active',
  `created_at` datetime(6) NOT NULL,
  `created_by` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `updated_by` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_guid` (`guid`),
  KEY `idx_context_id` (`context_id`),
  KEY `idx_context_item_id` (`context_item_id`),
  KEY `idx_table_schema` (`table_schema`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `library_context_item_file_upload_entries` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `upload_id` bigint NOT NULL COMMENT '上传记录 ID（library_context_item_file_uploads.id）',
  `relative_path` varchar(512) NOT NULL COMMENT '解压根目录下相对路径（保留层级）',
  `file_name` varchar(512) NOT NULL COMMENT '文件名（basename）',
  `public_uri` varchar(512) NOT NULL COMMENT '对外访问 URI（/_artifacts/...）',
  `file_size_bytes` bigint DEFAULT NULL COMMENT '文件大小（字节）',
  `md5` char(32) DEFAULT NULL COMMENT '文件内容 MD5（hex 小写）',
  `created_at` datetime NOT NULL COMMENT '创建时间（UTC）',
  PRIMARY KEY (`id`),
  KEY `idx_lci_fu_entries_upload_id` (`upload_id`),
  KEY `idx_lci_fu_entries_upload_id_relative_path` (`upload_id`,`relative_path`),
  KEY `idx_lci_fu_entries_file_name` (`file_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='上下文条目文件上传（归档解压）明细表';

CREATE TABLE `library_context_item_file_uploads` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` char(36) NOT NULL COMMENT '记录 GUID',
  `context_id` bigint NOT NULL COMMENT '上下文空间 ID（library_contexts.id）',
  `context_item_id` bigint NOT NULL COMMENT '上下文条目 ID（library_context_items.id）',
  `original_filename` varchar(512) NOT NULL COMMENT '用户上传的原始文件名（已做安全字符处理）',
  `stored_filename` varchar(512) NOT NULL COMMENT '磁盘存储文件名（含 UUID 前缀）',
  `relative_path` varchar(1024) NOT NULL COMMENT '相对 artifacts 根目录的路径',
  `public_uri` varchar(1024) NOT NULL COMMENT '对外访问路径，如 /_artifacts/...',
  `md5` char(32) NOT NULL COMMENT '文件内容 MD5（hex 小写）',
  `is_archive` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否归档解压上传（zip/tar/tgz）',
  `archive_type` varchar(16) DEFAULT NULL COMMENT '归档类型：zip/tar/tgz',
  `extracted_root_relative_path` varchar(1024) DEFAULT NULL COMMENT '解压根目录相对路径',
  `file_count` bigint DEFAULT NULL COMMENT '解压后文件数',
  `total_file_size_bytes` bigint DEFAULT NULL COMMENT '解压后总大小（字节）',
  `content_type` varchar(255) DEFAULT NULL COMMENT 'HTTP Content-Type',
  `file_size_bytes` bigint DEFAULT NULL COMMENT '文件大小（字节）',
  `uploaded_by` varchar(128) NOT NULL COMMENT '上传人用户 ID',
  `uploaded_at` datetime NOT NULL COMMENT '上传时间（UTC）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_library_context_item_file_uploads_guid` (`guid`),
  UNIQUE KEY `uk_lci_fu_item_md5` (`context_item_id`,`md5`),
  KEY `idx_lci_fu_context_item_uploaded_at` (`context_item_id`,`uploaded_at`),
  KEY `idx_lci_fu_context_uploaded_at` (`context_id`,`uploaded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='type=file 上下文条目文件上传历史';

CREATE TABLE `library_context_items` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增，对应 items.id',
  `guid` char(36) NOT NULL COMMENT '上下文条目 GUID',
  `context_id` bigint NOT NULL COMMENT '所属上下文空间 ID，对应 LibraryContexts.id',
  `name` varchar(255) NOT NULL COMMENT '条目名称，例如 main-repo',
  `type` varchar(50) NOT NULL COMMENT '条目类型，例如 codebase',
  `uri` varchar(255) DEFAULT NULL COMMENT 'Item URI (e.g., repository URL)',
  `branch` varchar(255) DEFAULT NULL COMMENT 'Branch name for codebase items',
  `project_repository_id` bigint DEFAULT NULL COMMENT 'type=codebase 时引用 project_repositories.id',
  `promote_file_path` varchar(1024) DEFAULT NULL COMMENT 'promote文件路径(仓库相对路径)',
  `toolset_id` varchar(128) DEFAULT NULL COMMENT '所选工具集 ID（catalog toolsets-registry 条目的 id），type=codebase 时使用',
  `toolset_command` varchar(256) DEFAULT NULL COMMENT '所选工具集下的具体 command（如 /ctx-analysis-generic），type=codebase 时使用',
  `connection_uri` varchar(1024) DEFAULT NULL COMMENT 'Database connection URI, used when type=database',
  `status` varchar(20) NOT NULL DEFAULT 'Active' COMMENT '状态：Active / Deactive（逻辑删除用）',
  `sync_status` varchar(50) NOT NULL COMMENT '同步状态，对应 syncStatus，如 Success',
  `synced_at` datetime DEFAULT NULL COMMENT '最近同步时间，对应 syncedAt',
  `synced_by` varchar(128) DEFAULT NULL COMMENT '最近同步人，对应 syncedBy',
  `created_at` datetime NOT NULL COMMENT '创建时间，对应 createdAt',
  `created_by` varchar(128) NOT NULL COMMENT '创建人，对应 createdBy',
  `updated_at` datetime NOT NULL COMMENT '更新时间，对应 updatedAt',
  `updated_by` varchar(128) NOT NULL COMMENT '更新人，对应 updatedBy',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_library_context_items_guid` (`guid`),
  KEY `idx_library_context_items_context_id` (`context_id`),
  KEY `idx_library_context_items_context_id_status` (`context_id`,`status`),
  KEY `idx_library_context_items_type` (`type`),
  KEY `idx_library_context_items_project_repository_id` (`project_repository_id`),
  KEY `idx_library_context_items_branch` (`branch`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='上下文空间条目表';

CREATE TABLE `library_context_results` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `guid` char(36) NOT NULL COMMENT '结果记录 GUID',
  `context_id` bigint NOT NULL COMMENT '上下文空间 ID（library_contexts.id）',
  `context_item_id` bigint NOT NULL COMMENT '上下文条目 ID（library_context_items.id）',
  `sync_history_id` bigint NOT NULL COMMENT '同步历史 ID（library_context_sync_history.id）',
  `artifact_name` varchar(255) NOT NULL COMMENT 'artifact 名称',
  `file_name` varchar(512) NOT NULL COMMENT '文件名（例如 project-overview.md）',
  `file_content` longtext NOT NULL COMMENT '文件内容',
  `created_at` datetime NOT NULL COMMENT '创建时间（UTC）',
  `created_by` varchar(128) NOT NULL COMMENT '创建人（后续可替换为用户 ID）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_library_context_results_guid` (`guid`),
  KEY `idx_lcr_context_id` (`context_id`),
  KEY `idx_lcr_context_item_id` (`context_item_id`),
  KEY `idx_lcr_sync_history_id` (`sync_history_id`),
  KEY `idx_lcr_context_id_file_name` (`context_id`,`file_name`),
  KEY `idx_lcr_sync_history_id_file_name` (`sync_history_id`,`file_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='上下文空间同步结果表';

CREATE TABLE `library_context_sync_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `guid` char(36) NOT NULL COMMENT '同步记录 GUID',
  `context_id` bigint NOT NULL COMMENT '上下文空间 ID（library_contexts.id）',
  `context_item_id` bigint NOT NULL COMMENT '上下文条目 ID（library_context_items.id）',
  `repo_name` varchar(255) NOT NULL COMMENT '仓库显示名（前端展示用）',
  `repo_url` varchar(1024) NOT NULL COMMENT '仓库 URL（例如 https://github.com/owner/repo）',
  `branch` varchar(128) NOT NULL COMMENT '分支名',
  `triggered_at` datetime NOT NULL COMMENT '触发时间（UTC）',
  `triggered_by` varchar(128) NOT NULL COMMENT '触发人（后续可替换为用户 ID）',
  `run_id` bigint DEFAULT NULL COMMENT 'GitHub Actions runId',
  `server_id` bigint DEFAULT NULL COMMENT '执行该同步任务的 global_repositories.id',
  `workflow_url` varchar(1024) DEFAULT NULL COMMENT 'Workflow URL',
  `workflow_status` varchar(32) DEFAULT NULL COMMENT 'queued / in_progress / completed',
  `workflow_conclusion` varchar(32) DEFAULT NULL COMMENT 'success / failure / cancelled / skipped',
  `status` varchar(32) NOT NULL COMMENT '业务状态：Success / Failed',
  `error_message` varchar(2048) DEFAULT NULL COMMENT '错误信息',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间（UTC）',
  `duration` bigint DEFAULT NULL COMMENT '耗时（秒）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_library_context_sync_history_guid` (`guid`),
  KEY `idx_lcsh_context_id_triggered_at` (`context_id`,`triggered_at`),
  KEY `idx_lcsh_context_item_id_triggered_at` (`context_item_id`,`triggered_at`),
  KEY `idx_lcsh_status_triggered_at` (`status`,`triggered_at`),
  KEY `idx_lcsh_run_id` (`run_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='上下文空间同步历史表';

CREATE TABLE `library_contexts` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增，对应 JSON 中 id',
  `guid` char(36) NOT NULL COMMENT '上下文空间 GUID',
  `name` varchar(255) NOT NULL COMMENT '上下文空间名称',
  `description` text COMMENT '上下文空间描述',
  `collection_id` bigint NOT NULL COMMENT '集合 ID，对应 collectionId',
  `project_id` bigint NOT NULL COMMENT '项目 ID，对应 projectId',
  `owner_id` bigint NOT NULL COMMENT '拥有者用户 ID，对应 ownerId',
  `status` varchar(32) NOT NULL DEFAULT 'Active' COMMENT '状态，如 Active/Archived',
  `auto_sync_enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否自动同步，对应 autoSyncEnabled',
  `project_repository_id` bigint DEFAULT NULL COMMENT 'Project repository config ID for context space',
  `created_at` datetime NOT NULL COMMENT '创建时间，对应 createdAt',
  `created_by` varchar(128) NOT NULL COMMENT '创建人，对应 createdBy',
  `updated_at` datetime NOT NULL COMMENT '更新时间，对应 updatedAt',
  `updated_by` varchar(128) NOT NULL COMMENT '更新人，对应 updatedBy',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_library_contexts_guid` (`guid`),
  KEY `idx_library_contexts_collection_id` (`collection_id`),
  KEY `idx_library_contexts_project_id` (`project_id`),
  KEY `idx_library_contexts_owner_id` (`owner_id`),
  KEY `idx_library_contexts_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='上下文空间表';

CREATE TABLE `one_time_task_control` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `task_code` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `task_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_one_time_task_control_task_code` (`task_code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='One-time task execution control';

CREATE TABLE `org_create_quota_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `subject_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Fixed: USER_TYPE',
  `subject_key` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SUPER_ADMIN | NON_SUPER_ADMIN',
  `quota_limit` int NOT NULL COMMENT '-1 means unlimited',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated time (UTC)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_org_create_quota_rules_subject` (`subject_type`,`subject_key`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `org_create_usage` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `user_id` bigint unsigned NOT NULL COMMENT 'FK users.id',
  `used_count` int NOT NULL DEFAULT '0' COMMENT 'Total created organization count',
  `last_used_at` datetime DEFAULT NULL COMMENT 'Last create time (UTC)',
  `last_collection_id` bigint unsigned DEFAULT NULL COMMENT 'Last created collection id',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated time (UTC)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_org_create_usage_user_id` (`user_id`),
  KEY `ix_org_create_usage_last_collection_id` (`last_collection_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_crypto_key` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key_version` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public_key_pem` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `private_key_ciphertext` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `key_encrypt_alg` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLAINTEXT',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_password_crypto_key_version` (`key_version`),
  KEY `idx_password_crypto_key_active_id` (`is_active`,`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Versioned password crypto keys';

CREATE TABLE `personal_access_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_prefix` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hash_algo` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BCRYPT',
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `rotated_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pat_user_name` (`user_id`,`name`),
  KEY `idx_pat_user_id` (`user_id`),
  KEY `idx_pat_expires_at` (`expires_at`),
  KEY `idx_pat_revoked_at` (`revoked_at`),
  KEY `idx_pat_user_status_page` (`user_id`,`revoked_at`,`expires_at`,`created_at`),
  CONSTRAINT `fk_pat_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `pipeline_servers` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uname` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `server_type` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '服务端类型：github | jenkins',
  `repository_source_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'github' COMMENT '仓库源类型：github',
  `base_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库 Base URL',
  `repository_auth_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'token' COMMENT '鉴权方式：none | token',
  `token` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '访问 Token',
  `repository_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '仓库名称/路径（Jenkins 场景为 Job 名称）',
  `workflow_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '工作流 ID / 路径',
  `default_branch` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '默认分支',
  `jenkins_git_repository_source_type` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库源类型：github',
  `jenkins_git_base_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库 Base URL',
  `jenkins_git_repository_auth_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库鉴权方式：none | token',
  `jenkins_git_token` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库 token',
  `jenkins_git_repository_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库名称/路径',
  `jenkins_git_default_branch` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Jenkins 子仓库默认分支',
  `jenkins_context_sync_jenkinsfile` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '上下文同步 Jenkinsfile 文件名（classpath:pipelines/）',
  `jenkins_workspace_execution_jenkinsfile` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '工作区执行 Jenkinsfile 文件名（classpath:pipelines/）',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active',
  `date_created` datetime NOT NULL,
  `created_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_updated` datetime NOT NULL,
  `updated_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pipeline_servers_uname` (`uname`),
  KEY `idx_pipeline_servers_server_type` (`server_type`),
  KEY `idx_pipeline_servers_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='流水线服务端配置表';

CREATE TABLE `project_collections` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Stable GUID',
  `collection_uid` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Stable UID used in routes, e.g. core-banking',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Collection display name',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT 'Description',
  `date_created` datetime NOT NULL COMMENT 'Created time (UTC)',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Creator name',
  `date_updated` datetime NOT NULL COMMENT 'Last updated time (UTC)',
  `updated_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Last updater name',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT 'active / inactive',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_project_collections_guid` (`guid`),
  UNIQUE KEY `uk_project_collections_collection_uid` (`collection_uid`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `project_repositories` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `project_id` bigint NOT NULL COMMENT '所属项目 ID，对应 projects.id',
  `repository_source_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gitlab' COMMENT '仓库源类型：gitlab / github / custom（自建须填 base_url，API 与 GitLab 兼容）',
  `base_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库源 Base URL，如 https://gitlab.example.com',
  `git_push_base_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仅 custom 可选：git push 使用的 Base URL，与 base_url 可不同',
  `token` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '访问 Token（API 返回时脱敏）',
  `repository_auth_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'token' COMMENT '鉴权方式：none | token',
  `repository_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '仓库名称或路径，如 group/repo',
  `default_branch` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '默认分支，如 main',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active' COMMENT '状态：Active / Deactive',
  `date_created` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
  `created_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `date_updated` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
  `updated_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`),
  KEY `idx_project_repositories_project_id` (`project_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目仓库表';

CREATE TABLE `projects` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '全局唯一标识 (UUID)，对应 JSON: guid',
  `project_uid` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '项目唯一标识 (slug)，对应 JSON: project_uid',
  `collection_id` bigint NOT NULL COMMENT '所属集合 ID，对应 JSON: collectionId',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '项目名称，对应 JSON: name',
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending' COMMENT '状态：Active / Pending / Completed，对应 JSON: status',
  `start_date` date DEFAULT NULL COMMENT '开始日期，对应 JSON: startDate',
  `end_date` date DEFAULT NULL COMMENT '结束日期，对应 JSON: endDate',
  `date_created` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间，对应 JSON: dateCreated',
  `created_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人，对应 JSON: createdBy',
  `date_updated` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间，对应 JSON: dateUpdated',
  `updated_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人，对应 JSON: updatedBy',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_projects_guid` (`guid`),
  UNIQUE KEY `uk_projects_project_uid` (`project_uid`),
  KEY `idx_projects_collection_id` (`collection_id`),
  KEY `idx_projects_status` (`status`),
  KEY `idx_projects_date_created` (`date_created`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='项目表';

CREATE TABLE `reporting_events` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `event` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '上报事件名称，固定值 REPORT_DATA',
  `batch_id` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '客户端生成的批次标识，格式 {timestamp}-{random}',
  `event_count` int NOT NULL COMMENT '本次请求声明的 events 数组元素数量',
  `events` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '事件明细 JSON 数组，支持 session_start/session_end/tool_call/res_install',
  `active_workspace_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '客户端上报的当前激活工作空间 ID',
  `event_timestamp` datetime NOT NULL COMMENT '服务端接收该次上报请求的时间',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_batch_id` (`batch_id`),
  KEY `idx_event_timestamp` (`event_timestamp`),
  KEY `idx_reporting_events_workspace_timestamp` (`active_workspace_id`,`event_timestamp`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='事件上报表：记录会话生命周期、工具调用与资源安装等事件';

CREATE TABLE `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Role identifier (e.g. super-admin)',
  `display_name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Role display name',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Role description',
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT 'Status: active/inactive',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated time (UTC)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_roles_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `super_admin_operation_audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `operation_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CREATE|PROMOTE|DEMOTE|RESET_PASSWORD|ENABLE|DISABLE|WHITELIST_GRANT|WHITELIST_REVOKE',
  `operator_user_id` bigint unsigned DEFAULT NULL COMMENT 'Operator user id',
  `target_user_id` bigint unsigned DEFAULT NULL COMMENT 'Target user id',
  `request_payload` json DEFAULT NULL COMMENT 'Sanitized request payload',
  `result_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SUCCESS|FAILED|REJECTED',
  `error_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Business error code',
  `error_message` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Error message',
  `client_ip` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Client IP',
  `user_agent` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Client User-Agent',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  PRIMARY KEY (`id`),
  KEY `idx_sa_audit_operator` (`operator_user_id`),
  KEY `idx_sa_audit_target` (`target_user_id`),
  KEY `idx_sa_audit_operation_created` (`operation_type`,`created_at`),
  KEY `idx_sa_audit_result_created` (`result_status`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `super_admin_operator_whitelist` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `operator_user_id` bigint unsigned NOT NULL COMMENT 'Authorized operator user id (users.id)',
  `operator_email_snapshot` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Operator email snapshot for troubleshooting',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' COMMENT 'active | inactive',
  `remark` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Remark',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Creator (user id or system)',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Updated time (UTC)',
  `updated_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Updater (user id or system)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_super_admin_operator_whitelist_user` (`operator_user_id`),
  KEY `idx_super_admin_operator_whitelist_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_mappings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `bank_user_id` bigint unsigned NOT NULL,
  `mapping_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BOUND',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_mappings_user_id` (`user_id`),
  UNIQUE KEY `uk_user_mappings_bank_user_id` (`bank_user_id`),
  KEY `idx_user_mappings_status` (`mapping_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_rule_mappings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `user_id` bigint unsigned NOT NULL COMMENT 'FK users.id',
  `collection_id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Collection id or * for all collections',
  `project_id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Project id or * for all projects',
  `rule_id` bigint unsigned NOT NULL COMMENT 'Rule id (typically roles.id)',
  `rule_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Role identifier, e.g. super-admin',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_rule_mappings_unique` (`user_id`,`collection_id`,`project_id`,`rule_id`),
  KEY `ix_user_rule_mappings_user_id` (`user_id`),
  KEY `ix_user_rule_mappings_collection_id` (`collection_id`),
  KEY `ix_user_rule_mappings_project_id` (`project_id`),
  KEY `ix_user_rule_mappings_rule_id` (`rule_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique email (login identifier)',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Password hash',
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'First name',
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Last name',
  `username` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '身份源展示姓名（users.username），可含中文',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '1-active, 0-inactive, 2-locked, etc.',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time (UTC)',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated time (UTC)',
  `register_source` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOCAL' COMMENT '注册来源枚举: LOCAL=注册页自助, ADMIN_PROVISIONED=超管后台创建, BANK_SSO=银行SSO等',
  `login_page_allowed` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1=允许登录页密码登录,0=禁止',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `workspace_artifacts` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `guid` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '全局唯一标识',
  `workspace_id` bigint NOT NULL COMMENT '所属工作空间 ID，关联 workspaces.id',
  `run_history_id` bigint DEFAULT NULL COMMENT '产生该制品的工作空间运行记录 ID，关联 workspace_run_history.id',
  `storage_name` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '制品存储名称（文件系统中的实际名称）',
  `relative_path` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '制品在工作空间文件夹中的相对路径',
  `artifact_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'output' COMMENT '制品类型：output / log / report / archive / other',
  `file_size_bytes` bigint DEFAULT NULL COMMENT '文件大小（字节）',
  `mime_type` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'MIME 类型，如 application/zip、text/plain 等',
  `file_entries` text COLLATE utf8mb4_unicode_ci COMMENT '提取的文件清单（JSON 数组），每个元素含 relativePath / fileName / fileSizeBytes',
  `total_file_size_bytes` bigint DEFAULT NULL COMMENT '所有提取文件的大小总和（字节）',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Active' COMMENT '状态：Active / Archived / Deleted',
  `created_at` datetime NOT NULL COMMENT '创建时间',
  `created_by` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '创建人',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_workspace_artifacts_guid` (`guid`),
  KEY `idx_workspace_artifacts_workspace_id` (`workspace_id`),
  KEY `idx_workspace_artifacts_run_history_id` (`run_history_id`),
  KEY `idx_workspace_artifacts_storage_name` (`storage_name`),
  KEY `idx_workspace_artifacts_status` (`status`),
  CONSTRAINT `fk_wa_run_history` FOREIGN KEY (`run_history_id`) REFERENCES `workspace_run_history` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_wa_workspace` FOREIGN KEY (`workspace_id`) REFERENCES `workspaces` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作空间执行制品表';

CREATE TABLE `workspace_relations` (
  `workspace_id` bigint NOT NULL COMMENT '工作空间 ID',
  `kind` varchar(20) NOT NULL COMMENT '关联类型: toolset | context | spec',
  `ref_id` varchar(64) NOT NULL COMMENT '关联 ID（toolset_id/spec_id 为字符串，context_id 为数字转字符串）',
  PRIMARY KEY (`workspace_id`,`kind`,`ref_id`),
  KEY `idx_workspace_relations_kind_ref_id` (`kind`,`ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='工作空间-工具集/上下文/规范 关系表';

CREATE TABLE `workspace_resource_links` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `workspace_id` bigint NOT NULL COMMENT 'workspaces.id',
  `resource_kind` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CONTEXT | TOOLSET | SPEC',
  `library_context_id` bigint DEFAULT NULL COMMENT 'library_contexts.id，仅 CONTEXT',
  `resource_id` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源ID（快照）',
  `resource_guid` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源GUID（快照）',
  `resource_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源名称（快照）',
  `resource_description` text COLLATE utf8mb4_unicode_ci COMMENT '资源描述（快照）',
  `resource_version` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源版本（快照）',
  `resource_entry_point` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源入口（快照）',
  `resource_date_created` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源创建时间（快照）',
  `resource_date_updated` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源更新时间（快照）',
  `resource_created_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源创建人（快照）',
  `resource_updated_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '资源更新人（快照）',
  PRIMARY KEY (`id`),
  KEY `idx_wrl_workspace` (`workspace_id`),
  KEY `idx_wrl_library_context` (`library_context_id`),
  KEY `idx_wrl_kind` (`resource_kind`),
  CONSTRAINT `fk_wrl_library_context` FOREIGN KEY (`library_context_id`) REFERENCES `library_contexts` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_wrl_workspace` FOREIGN KEY (`workspace_id`) REFERENCES `workspaces` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_wrl_shape` CHECK ((((`resource_kind` = _utf8mb4'CONTEXT') and (`library_context_id` is not null)) or ((`resource_kind` in (_utf8mb4'TOOLSET',_utf8mb4'SPEC')) and (`resource_id` is not null) and (char_length(trim(`resource_id`)) > 0) and (`library_context_id` is null))))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作空间-上下文/工具集/规约 关联表';

CREATE TABLE `workspace_run_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `guid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `workspace_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prompt_text` text COLLATE utf8mb4_unicode_ci,
  `repo_url` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL,
  `branch` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `triggered_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `triggered_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `run_id` bigint DEFAULT NULL,
  `workflow_url` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workflow_status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workflow_conclusion` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `completed_at` timestamp NULL DEFAULT NULL,
  `duration` int DEFAULT NULL,
  `verbose` tinyint(1) NOT NULL DEFAULT '1',
  `output_format` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pr_url` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `server_id` bigint DEFAULT NULL COMMENT 'pipeline_servers.id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `guid` (`guid`),
  KEY `idx_run_history_guid` (`guid`),
  KEY `idx_run_history_workspace_id` (`workspace_id`),
  KEY `idx_run_history_status` (`status`),
  KEY `idx_run_history_workflow_status` (`workflow_status`),
  KEY `idx_run_history_run_id` (`run_id`),
  KEY `idx_run_history_triggered_at` (`triggered_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `workspaces` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增，对应 JSON 中 id',
  `guid` char(36) NOT NULL COMMENT '工作空间 GUID',
  `name` varchar(255) NOT NULL COMMENT '工作空间名称',
  `description` text COMMENT '工作空间描述',
  `collection_id` bigint NOT NULL COMMENT '集合 ID，对应 collectionId',
  `project_id` bigint NOT NULL COMMENT '项目 ID，对应 projectId',
  `owner_id` bigint NOT NULL COMMENT '拥有者用户 ID，对应 ownerId',
  `type` varchar(20) NOT NULL DEFAULT 'CODE' COMMENT 'CODE | NORMAL',
  `project_repository_id` bigint DEFAULT NULL COMMENT '工作空间使用的项目仓库配置 ID，对应 project_repositories.id（可不传，按 project_id 推导）',
  `status` varchar(32) NOT NULL DEFAULT 'Active' COMMENT '状态，如 Active/Archived',
  `created_at` datetime NOT NULL COMMENT '创建时间，对应 createdAt',
  `created_by` varchar(128) NOT NULL COMMENT '创建人',
  `updated_at` datetime DEFAULT NULL COMMENT '更新时间，对应 updatedAt',
  `updated_by` varchar(128) DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_workspaces_guid` (`guid`),
  KEY `idx_workspaces_collection_id` (`collection_id`),
  KEY `idx_workspaces_project_id` (`project_id`),
  KEY `idx_workspaces_owner_id` (`owner_id`),
  KEY `idx_workspaces_project_repository_id` (`project_repository_id`),
  KEY `idx_workspaces_status` (`status`),
  CONSTRAINT `fk_workspaces_project_repository` FOREIGN KEY (`project_repository_id`) REFERENCES `project_repositories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='工作空间表';

