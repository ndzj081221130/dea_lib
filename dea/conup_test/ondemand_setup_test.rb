# UTF-8

require "set"
require "../conup/ondemand_setup"


id = "AuthComponent"
version ="1.0"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Set.new #children#
#deps << ""
indeps = Set.new #parents
indeps << "ProcComponent"
indeps << "PortalComponent"


implType="Java_POJO"
 
compAuth = Dea::ComponentObject.instance(id,version,alg,freeConf,deps,indeps,implType)

ondemand = VCOndemandSetup.new(compAuth)
