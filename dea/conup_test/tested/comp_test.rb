# UTF-8

require "../conup/component"
require "set"

id = "AuthComponent"
version ="8010"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Set.new #children#
indeps = Set.new #parents
indeps << "ProcComponent"
indeps << "PortalComponent"


implType="Java_POJO"
 
 compAuth = Dea::ComponentObject.new(id,version,alg,freeConf,deps,indeps,implType)
# 
 puts compAuth

# id = "ProcComponent"
# version="1.0"
# alg="consistency"
# freeConf="concurrent_version_for_freeness"
# deps = Array.new #children#
# deps << "AuthComponent"
# deps << "DBComponent"
# 
# indeps = Array.new #parents
# indeps << "PortalComponent"
# implType="Java_POJO"
# compProc = Dea::ComponentObject.instance(id,version,alg,freeConf,deps,indeps,implType)
# 
# puts compProc # cause component object is a singleton