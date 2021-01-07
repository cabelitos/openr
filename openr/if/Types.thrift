/*
 * Copyright (c) 2014-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

namespace cpp openr.thrift
namespace cpp2 openr.thrift
namespace go openr.Types
namespace py openr.Types
namespace py3 openr.thrift
namespace lua openr.Types
namespace wiki Open_Routing.Thrift_APIs.Types

include "Network.thrift"
include "Lsdb.thrift"

/**
 * Default area constant. This is relevant only during the course of transition
 * to new area functionality.
 */
const string kDefaultArea = "0"

/**
 * @deprecated - DUAL message type
 */
enum DualMessageType {
  UPDATE = 1,
  QUERY = 2,
  REPLY = 3,
}

/**
 * @deprecated - A single DUAL message
 */
struct DualMessage {
  /**
   * destination-id
   */
  1: string dstId;

  /**
   * report-distance towards dst-id
   */
  2: i64 distance;

  /**
   * message type
   */
  3: DualMessageType type;
}

/**
 * @deprecated - Container representing multiple dual messages
 */
struct DualMessages {
  /**
   * sender node-id
   */
  1: string srcId;

  /**
   * List of dual-messages
   */
  2: list<DualMessage> messages;
}

/**
 * @deprecated - Number of packets and dual-messages sent/recv for a neighbor
 * one packet may contain multiple messages
 */
struct DualPerNeighborCounters {
  1: i64 pktSent = 0;
  2: i64 pktRecv = 0;
  3: i64 msgSent = 0;
  4: i64 msgRecv = 0;
}

/**
 * @deprecated - Dual exchange message counters for a given root per neighbor
 */
struct DualPerRootCounters {
  1: i64 querySent = 0;
  2: i64 queryRecv = 0;
  3: i64 replySent = 0;
  4: i64 replyRecv = 0;
  5: i64 updateSent = 0;
  6: i64 updateRecv = 0;
  7: i64 totalSent = 0;
  8: i64 totalRecv = 0;
}

/**
 * @deprecated - Map of neighbor-node to neighbor-counters
 */
typedef map<string, DualPerNeighborCounters>
  (cpp.type =
    "std::unordered_map<std::string, /* neighbor */ openr::thrift::DualPerNeighborCounters>")
  NeighborCounters

/**
 * @deprecated - Map of root-node to root-counters
 */
typedef map<string, map<string, DualPerRootCounters>>
  (cpp.type =
    "std::unordered_map<std::string, /* root */ std::map<std::string /* neighbor */, openr::thrift::DualPerRootCounters>>")
  RootCounters

/**
 * @deprecated - All DUAL related counters
 */
struct DualCounters {
  1: NeighborCounters neighborCounters;
  2: RootCounters rootCounters;
}

/**
 * `V` of `KV` Store. It encompasses the data that needs to be synchronized
 * along with few attributes that helps ensure eventual consistency.
 */
struct Value {
  /**
   * Current version of this value. Higher version value replaces the lower one.
   * Applications updating the data of an existing KV will always bump up the
   * version.
   *
   * 1st tie breaker - Prefer higher
   */
  1: i64 version;

  /**
   * The node that originate this Value. Higher value replaces the lower one if
   * (version) is same.
   *
   * 2nd tie breaker - Prefer higher
   */
  3: string originatorId

  /**
   * Application data. This is opaque to KvStore itself. It is upto the
   * applications to define encoding/decoding of data. Within Open/R, we uses
   * thrift structs to avoid burden of encoding/decoding.
   *
   * 3rd tie breaker - Prefer higher
   *
   * KV update with no application data is considered as TTL update. See below
   * for TTL and TTL version.
   */
  2: optional binary value

  /**
   * TTL in milliseconds associated with this Value. Originator sets the value.
   * An associated timer if fired will purge the value, if there is no ttl
   * update received.
   */
  4: i64 ttl;

  /**
   * Current version of the TTL. KV update with same (version, originator) but
   * higher ttl-version will reset the associated TTL timer to the new TTL value
   * in the update. Should be reset to 0 when the version increments.
   */
  5: i64 ttlVersion = 0;

  /**
   * Hash associated with `tuple<version, originatorId, value>`. Clients
   * should leave it empty and as will be computed by KvStore on `KEY_SET`
   * operation.
   */
  6: optional i64 hash;
}

/**
 * Map of key to value. This is a representation of KvStore data-base. Using
 * `std::unordered_map` in C++ for efficient lookups.
 */
typedef map<string, Value>
  (cpp.type = "std::unordered_map<std::string, openr::thrift::Value>") KeyVals

/**
 * @deprecated - Enum describing KvStore command type. This becomes obsolete
 * with the removal of dual functionality.
 */
enum Command {
  /**
   * Operations on keys in the store
   */
  KEY_SET   = 1,
  KEY_DUMP  = 3,

  /**
   * Dual message
   */
  DUAL = 10,

  /**
   * Set or uunset flooding-topology child
   */
  FLOOD_TOPO_SET = 11,
}

/**
 * Logical operator enum for querying
 */
enum FilterOperator {
  OR = 1,
  AND = 2,
}

/**
 * Request object for setting keys in KvStore.
 */
struct KeySetParams {
  /**
   * Entries, aka list of Key-Value, that are requested to be updated in a
   * KvStore instance.
   */
  2: KeyVals keyVals;

  /**
   * Solicit for an ack. If set to false will make request one-way. There won't
   * be any response set. This is obsolete with KvStore thrift migration.
   */
  3: bool solicitResponse = 1 (deprecated)

  /**
   * Optional attributes. List of nodes through which this publication has
   * traversed. Client shouldn't worry about this attribute. It is updated and
   * used by KvStore for avoiding flooding loops.
   */
  5: optional list<string> nodeIds

  /**
   * @deprecated - Optional flood root-id, indicating which SPT this publication
   * should be flooded on; if none, flood to all peers
   */
  6: optional string floodRootId;

  /**
   * Optional attribute to indicate timestamp when request is sent. This is
   * system timestamp in milliseconds since epoch
   */
  7: optional i64 timestamp_ms
}

/**
 * Request object for retrieving specific keys from KvStore
 */
struct KeyGetParams {
  1: list<string> keys
}

/**
 * Request object for retrieving KvStore entries or subscribing KvStore updates.
 * This is more powerful version than KeyGetParams.
 */
struct KeyDumpParams {
  /**
   * This is deprecated in favor of `keys` attribute
   */
  1: string prefix (deprecated)

  /**
   * Set of originator IDs to filter on
   */

  3: set<string> originatorIds

  /**
   * If set to true (default), ignore TTL updates. This is applicable for
   * subscriptions (aka streaming KvStore updates).
   */
  6: bool ignoreTtl = true

  /**
   * If set to true, data attribute (`value.value`) will be removed from
   * from response. This would greatly reduces the data that need to be sent to
   * client.
   */
  7: bool doNotPublishValue = false

  /**
   * Optional attribute to include keyValHashes information from peer.
   * 1) If NOT empty, ONLY respond with keyVals on which hash differs;
   *  2) Otherwise, respond with flooding element to signal DB change;
   */
  2: optional KeyVals keyValHashes

  /**
   * The default is OR for dumping KV store entries for backward compatibility.
   * The default will be changed to AND later. We can also make `oper`
   * mandatory later. The default for subscription is AND now.
   */
  4: optional FilterOperator oper

  /**
   * Keys to subscribe to in KV store so that consumers receive only certain
   * kinds of updates. For example, a consumer might be interesred in
   * getting "adj:.*" keys from open/r domain.
   */
  5: optional list<string> keys;
}

/**
 * Define KvStorePeerState to maintain peer's state transition
 * during peer coming UP/DOWN for initial sync.
 */
enum KvStorePeerState {
  IDLE = 0,
  SYNCING = 1,
  INITIALIZED = 2,
}

/**
 * Peer's publication and command socket URLs
 * This is used in peer add requests and in
 * the dump results
 */
struct PeerSpec {
  /**
   * Peer address over thrift for KvStore external sync
   */
  1: string peerAddr

  /**
   * cmd url for KvStore external sync over ZMQ
   */
  2: string cmdUrl (deprecated)

  /**
   * thrift port
   */
  4: i32 ctrlPort = 0

  /**
   * State of KvStore peering
   */
  5: KvStorePeerState state
}

/**
 * Unordered map for efficiency for peer to peer-spec
 * TODO: Use C++ struct instead. We don't really need efficiency for peers map
 * as it has few entries and occassional update.
 */
typedef map<string, PeerSpec>
  (cpp.type = "std::unordered_map<std::string, openr::thrift::PeerSpec>")
  PeersMap

/**
 * Parameters for KvStore peer addition
 * TODO: Use C++ struct instead
 */
struct PeerAddParams {
  /**
   * Map from nodeName to peer spec; we expect to
   * learn nodeName from HELLO packets, as it MUST
   * match the name supplied with Publication message
   */
  1: PeersMap peers
}

/**
 * parameters for peers deletion
 * TODO: Use C++ struct instead
 */
struct PeerDelParams {
  1: list<string> peerNames
}

/**
 * KvStore peer update request
 * TODO: Use C++ struct instead
 */
struct PeerUpdateRequest {
  1: string area
  2: optional PeerAddParams peerAddParams
  3: optional PeerDelParams peerDelParams
}

/**
 * @deprecated - set/unset flood-topo child
 */
struct FloodTopoSetParams {
  /**
   * spanning tree root-id
   */
  1: string rootId

  /**
   * from node-id
   */
  2: string srcId

  /**
   * set/unset a spanning tree child
   */
  3: bool setChild

  /**
   * action apply to all-roots or not
   * if true, rootId will be ignored and action will be applied to all roots
   */
  4: optional bool allRoots
}

/**
 * @deprecated
 */
typedef set<string>
  (cpp.type = "std::unordered_set<std::string>") PeerNames

/**
 * @deprecated - single spanning tree information
 */
struct SptInfo {
  // passive state or not
  1: bool passive
  // metric cost towards root
  2: i64 cost
  // optional parent if any (aka nexthop)
  3: optional string parent
  // a set of spt children
  4: PeerNames children
}

/**
 * @deprecated - map<root-id: SPT-info>
 */
typedef map<string, SptInfo>
  (cpp.type = "std::unordered_map<std::string, openr::thrift::SptInfo>")
  SptInfoMap

/**
 * All spanning tree(s) information
 */
struct SptInfos {
  /**
   * map<root-id: SptInfo>
   */
  1: SptInfoMap infos

  /**
   * all DUAL related counters
   */
  2: DualCounters counters

  /**
   * current flood-root-id if any
   */
  3: optional string floodRootId

  /**
   * current flooding peers
   */
  4: PeerNames floodPeers
}

/**
 * KvStore Request specification. A request to the server (tagged union)
 */
struct KvStoreRequest {
  /**
   * Command type. Set one of the optional parameter based on command
   */
  1: Command cmd

  /**
   * area identifier to identify the KvStoreDb instance (mandatory)
   */
  11: string area

  2: optional KeySetParams keySetParams
  3: optional KeyGetParams keyGetParams
  6: optional KeyDumpParams keyDumpParams
  9: optional DualMessages dualMessages
  10: optional FloodTopoSetParams floodTopoSetParams
}

/**
 * KvStore Response specification. This is also used to respond to GET requests
 */
struct Publication {
  /**
   * KvStore entries
   */
  2: KeyVals keyVals

  /**
   * List of expired keys. This is applicable for KvStore subscriptions and
   * flooding.
   * TODO: Expose more detailed information `expiredKeyVals` so that subscribers
   * can act on the values as well. e.g. in Decision/PrefixManager we no longer
   * need to rely on the key name to decode prefix/area/node and can use more
   * compact key formatting.
   */
  3: list<string> expiredKeys

  /**
   * Optional attributes. List of nodes through which this publication has
   * traversed. Client shouldn't worry about this attribute.
   */
  4: optional list<string> nodeIds

  /**
   * a list of keys that needs to be updated
   * this is only used for full-sync respone to tell full-sync initiator to
   * send back keyVals that need to be updated
   */
  5: optional list<string> tobeUpdatedKeys

  /**
   * optional flood root-id, indicating which SPT this publication should be
   * flooded on; if none, flood to all peers
   */
  6: optional string floodRootId (deprecated)

  /**
   * KvStore Area to which this publication belongs
   */
  7: string area

  /**
   * Optional timestamp when publication is sent. This is system timestamp
   * in milliseconds since epoch
   */
  8: optional i64 timestamp_ms
}

/**
 * @deprecated - Allocated prefix information. This is stored in the persistent
 * store and can be read via config get thrift API.
 */
struct AllocPrefix {
  /**
   * Seed prefix from which sub-prefixes are allocated
   */
  1: Network.IpPrefix seedPrefix

  /**
   * Allocated prefix length
   */
  2: i64 allocPrefixLen

  /**
   * My allocated prefix, i.e., index within seed prefix
   */
  3: i64 allocPrefixIndex
}

/**
 * @deprecated - Prefix allocation configuration. This is set in KvStore by
 * remote controller. The PrefixAllocator learns its own prefix, assign it on
 * the interface, and advertise it in the KvStore.
 *
 * See PrefixAllocator documentation for static configuration mode.
 */
struct StaticAllocation {
  /**
   * Map of node to allocated prefix. This map usually contains entries for all
   * the nodes in the network.
   */
  1: map<string /* node-name */, Network.IpPrefix> nodePrefixes;
}

/**
 * @deprecated - Map of node name to adjacency database. This is deprecated
 * and should go away once area migration is complete.
 */
typedef map<string, Lsdb.AdjacencyDatabase>
  (
    cpp.type =
    "std::unordered_map<std::string, openr::thrift::AdjacencyDatabase>"
  ) AdjDbs

/**
 * @deprecated - Map of node name to adjacency database. This is deprecated
 * in favor of `received-routes` and `advertised-routes` and should go away
 * once area migration is complete.
 */
typedef map<string, Lsdb.PrefixDatabase>
  (cpp.type = "std::unordered_map<std::string, openr::thrift::PrefixDatabase>")
  PrefixDbs

/**
 * Represents complete route database that is or should be programmed in
 * underlying platform.
 */
struct RouteDatabase {
  /**
   * Name of the node where these routes are to be programmed
   * @deprecated - This is not useful field and should be removed
   */
  1: string thisNodeName

  /**
   * An ordered list of events that can be used to derive the convergence time
   * @deprecated TODO - This should be removed in favor of perfEvents in
   * RouteDatabaseDelta.
   */
  3: optional Lsdb.PerfEvents perfEvents;

  /**
   * IPv4 and IPv6 routes with forwarding information
   */
  4: list<Network.UnicastRoute> unicastRoutes

  /**
   * Label routes with forwarding information
   */
  5: list<Network.MplsRoute> mplsRoutes
}

/**
 * Structure repesenting incremental changes to route database.
 */
struct RouteDatabaseDelta {
  /**
   * IPv4 or IPv6 routes to add or update
   */
  2: list<Network.UnicastRoute> unicastRoutesToUpdate

  /**
   * IPv4 or IPv6 routes to delete
   */
  3: list<Network.IpPrefix> unicastRoutesToDelete;

  /**
   * Label routes to add or update
   */
  4: list<Network.MplsRoute> mplsRoutesToUpdate

  /**
   * Label routes to delete
   */
  5: list<i32> mplsRoutesToDelete

  /**
   * An ordered list of events that leads to these route updates. It can be used
   * to derive the convergence time
   */
  6: optional Lsdb.PerfEvents perfEvents;
}

/**
 * Perf log buffer maintained by Fib
 */
struct PerfDatabase {
  /**
   * Name of local node.
   * @deprecated TODO - This field is of no relevance
   */
  1: string thisNodeName

  /**
   * Ordered list of historical performance events in ascending order of time
   */
  2: list<Lsdb.PerfEvents> eventInfo
}

/**
 * Details about an interface in Open/R
 */
struct InterfaceDetails {
  /**
   * Interface information such as name and addresses
   */
  1: Lsdb.InterfaceInfo info

  /**
   * Overload or drain status of the interface
   */
  2: bool isOverloaded

  /**
   * All adjacencies over this interface will inherit this override metric if
   * specified. Metric override is often used for soft draining of links.
   * NOTE: This metric is directional. Override should ideally be also set on
   * the other end of the interface.
   */
  3: optional i32 metricOverride

  /**
   * Backoff in milliseconds for this interface. Interface that flaps or goes
   * crazy will get penalized with longer backoff. See link-backoff
   * functionality in LinkMonitor documentation.
   */
  4: optional i64 linkFlapBackOffMs
}

/**
 * Information of all links of this node
 */
struct DumpLinksReply {
  /**
   * @deprecated - Name of the node. This is no longer of any relevance.
   */
  1: string thisNodeName

  /**
   * Overload or drain status of the node.
   */
  3: bool isOverloaded

  /**
   * Details of all the interfaces on system.
   */
  6: map<string, InterfaceDetails>
        (cpp.template = "std::unordered_map") interfaceDetails
}

/**
 * Set of attributes to uniquely identify an adjacency. It is identified by
 * (neighbor-node, local-interface) tuple.
 * TODO: Move this to Types.cpp
 */
struct AdjKey {
  /**
   * Name of the neighbor node
   */
  1: string nodeName;

  /**
   * Name of local interface over which an adjacency is established
   */
  2: string ifName;
}

/**
 * Struct to store internal override states for links (e.g. metric, overloaded
 * state) etc. This is not currently exposed via any API
 * TODO: Move this to Types.cpp
 */
struct LinkMonitorState {
  /**
   * Overload bit for Open-R. If set then this node is not available for
   * transit traffic at all.
   */
  1: bool isOverloaded = 0;

  /**
   * Overloaded links. If set then no transit traffic will pass through the
   * link and will be unreachable.
   */
  2: set<string> overloadedLinks;

  /**
   * Custom metric override for links. Can be leveraged to soft-drain interfaces
   * with higher metric value.
   */
  3: map<string, i32> linkMetricOverrides;

  /**
   * Label allocated to node (via RangeAllocator). `0` indicates null value
   */
  4: i32 nodeLabel = 0;

  /**
   * Custom metric override for adjacency
   */
  5: map<AdjKey, i32> adjMetricOverrides;
}

/**
 * Struct representing build information. Attributes are described in detail
 * in `openr/common/BuildInfo.h`
 */
struct BuildInfo {
  1: string buildUser;
  2: string buildTime;
  3: i64 buildTimeUnix;
  4: string buildHost;
  5: string buildPath;
  6: string buildRevision;
  7: i64 buildRevisionCommitTimeUnix;
  8: string buildUpstreamRevision;
  9: i64 buildUpstreamRevisionCommitTimeUnix;
  10: string buildPackageName;
  11: string buildPackageVersion;
  12: string buildPackageRelease;
  13: string buildPlatform;
  14: string buildRule;
  15: string buildType;
  16: string buildTool;
  17: string buildMode;
}