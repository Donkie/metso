
pcall(require, "mysqloo")
if not mysqloo then return end

local Promise = include("promise.lua")

local MysqlOO = {}
MysqlOO.__index = MysqlOO

function MysqlOO:query(query)
	local queryObj = self.db:query(query)

	local promise = Promise.new()

	queryObj.onSuccess = function(q, data)
		self.lastInsertID = q:lastInsert()
		self.lastAffectedRows = q:affectedRows()

		promise:resolve(data)
	end

	queryObj.onError = function(q, err, sql)
		promise:reject(err)
	end

	queryObj:start()

	return promise
end

function MysqlOO:queryLastInsertedId()
	return self.lastInsertID
end

function MysqlOO.new(opts)
	if not opts.host then error("Error: host must be specified when using MysqlOO as the driver") end
	if not opts.username then error("Error: username must be specified when using MysqlOO as the driver") end
	if not opts.password then error("Error: password must be specified when using MysqlOO as the driver") end

	local obj = setmetatable({}, MysqlOO)

	local db = mysqloo.connect( opts.host or "localhost",
								opts.username,
								opts.password,
								opts.database,
								opts.port or 3306,
								opts.socket or "")
	obj.db = db

	db:connect()
	db:wait()

	db:query("SET NAMES utf8mb4")

	return obj
end

return MysqlOO