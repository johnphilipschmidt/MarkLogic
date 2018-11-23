xquery version "3.0";

(:~
: User: philschmidt
: Date: 11/23/18
: Time: 4:59 PM
: To change this template use File | Settings | File Templates.
:)

module namespace Initial = "Initial";

(:Schmidt November 2018 :)
import module namespace jpsdoc = "http://schmidt.gov/jps-documents" at "ext/jps/libijps-documents.xqy";
import module namespace mem = 'http://xqdev.com/in-mem-update' at '/MarkLogic/appservices/utils/in-mem-update.xqy';
declare namespace document  ="http://schmidt.gov/jps/document/1.0";
declare namespace meta   = "http://schmidt.gov/jps/metadata/1.0";
declare namespace summ   = "http://schmidt.gov/jps/summary/1.0";
declare namespace src   = "http://schmidt.govijps/source/1.0";
declare namespace jps   = "http://schmidt.gov/jps/1.0";
declare namespace wf    = "http://schmidt.gov/jps/workflow/1.0";
declare namespace c     = "http://schmidt.gov/jps/common/1.0";


declare function local:maxVersion($docid) as xs:double {
    let $maxRecord:=
        (for $doc in xdmp:directory(fn:concat("/ingest/documentversions",$docid,"/"),"infinity")
        let $res := $docilmeta:jpsMetadata/meta:version/fn:number()
        return $res )
    return max($maxRecord)
};

declare function local:parameters() as map:map {
    let $parameterMap:= map:map()
    let $_:= map:put($parameterMap,"bank","bank")
    let $_:= map:put($parameterMap,"schmidt","schmidt")
    let $_:= map:put($parameterMap,"closed","Closed")
    let $_:= map:put($parameterMap,"open","Open")
    let $_:= map:put($parameterMap,"servername","server.schmidt.com:31700")
    let $_:= map:put($parameterMap,"userid","web")
    let $_:= map:put($parameterMap,"password","")
    return $parameterMap
};
(: Condtional processing of parameters ..:)


declare function local:maxSourceTypeVersion($docid,$sourceType,$status) as xs:double {
    let $maxVersion-Query :=
        cts:and-query((
            cts:directory-query("/ingest/documentversions/","infinity"),
            cts:element-value-query(xs:QName("meta:documentld"),fn:string($docid)
            )))
    return $maxVersion-Query
};


(: Construct the merged document :)

declare function local:documentMerge($docid,$maxbankVersion,$schmidtVersion,$parameterMap) as document-node() {
(: Construct the query to find the highest schmidt not in workflow that is closed:)
(: curl -k -u webserviceuser:password -X GET --header "Accept: application/}son" https://vredjpsasa03.tacschmidt.com:31700/documentSvc/api/v1/docs/2001329/78/merge/77?mergeMetac true:)
(: Execute merge and save :)
    let $USERID := "webserviceuser"
    let $PASSWORD := ""

    let $SERVER_NAME := "vredjpsasa03.tacschmidt.com:31700" return

    (:let $_:=" https://" I I $SERVER_NAME I I "fid930Svc/api/v1/docsr I I $docid I "/" I I $maxbankVersior merger I I $schmidtVersion I I "?mergeMetadata=true&amp;format=xml" :)

    (:let Surl:="https://" ||{map:get($parameterMap,"servername") }||"/documentSvc/api/v1/docs"|| $docid || "/"||$maxbankVersion ||"/merger ||"/"||"$schmidtVersion ||"?mergeMetadata=true&amp;format=xml" :)
        let $url:=""
        let $options :=
            <options xmins="xdmp:http" >
                <authentication method="basic">
                    <username>{map:get(SparameterMap,"userid")}</username>
                    <password>{map:get(SparameterMap,"password")}</password>
                </authentication> <verify-cert>false</verify-cert> </options>

        (: Get the document to UPDATE constructed from merge:)

        let $doc-to-update as document-node():= document{xdmp:http-get ($url, $options)/jps:jpsRecord}
        (: Change the new version to closed in memory:)

        let $doc-to-update := mem:node-replace($doc-to-update//meta:status,element meta:status{"Closed"})
        let $notification :=
            <meta:notification>
                <c:action>Data Correction</c:action>
                <c:description>bank Close Fix: Forced Close No export</c:description>
                <c:notificationType>DATA_CLEANUP</c:notificationType>
                <c:severity>INFO</c:severity>
                <c:system>schmidt</c:system>
                <c:subsystem>document</c:subsystem>
                <c:reason>To fix the schmidt Closed Records</c:reason>
                <cnotificationDateTime>{fn:current-dateTime()}</c:notificationDateTime>
            </meta:notification>

        let $insertNewNotificationList :=
            <meta:notifications>
                <meta:notification>
                    <c:action>Data Correction</c:action>
                    <c:description>bank Close Fix: Forced Close No export</c:description>
                    <c:notificationType>DATA_CLEANUP</c:notificationType>
                    <c:severity>INFO</c:severity>
                    <c:system>schmidt</c:system>
                    <c:subsystem>document</c:subsystem>
                    <c:reason>Fixes the schmidt Closed Records</c:reason>
                    <c:notificationDateTime>{fn:current-dateTime()}</c:notificationDateTime>
                    <c:inputltem></c:inputltem>
                </meta:notification>
            </meta:notifications>

        let $context:=($doc-to-update/jps:jpsRecord/meta:jpsMetadata/*[ local-name() = ('recordLinks', 'attachments', 'notificationLinks', 'notifications')])[last()]

        return

            let $doc-to-update :=
                if ( exists($context/local-name()))
                then
                    switch ($context/local-name())
                        case "recordLinks" return mem:node-insert-after($doc-to-update//meta:recordLinks, $insertNewNotificationList)
                        case "attachments" return mem:node-insert-after($doc-to-update//meta:sourceLinks, $insertNewNotificationList)
                        case "notificationlinks" return mem:node-insert-after($doc-to-update//meta:attachments, $insertNewNotificationList)
                        case "notifications" return mem:node-insert-child($doc-to-update//meta:notifications, $notification)
                        default return mem:node-insert-after($doc-to-update//meta:sourceLinks, $insertNewNotificationList)

                else
                    xdmp:log("Error: document structure is in question")

            let $_:=xdmp:log(" Notification Insert Context:"||$context)
            return $doc-to-update
};

declare function local:documentSave( $doc-to-update) {
(:SAVE the new version and LR of the Record:)
    let $save-ret :=
        if ($doc-to-update/jps:jpsRecord)
        then

            jpsdoc:save-document-latest-and-version
            ( "document",
                    $doc-to-update,
                    "SYSTEM",
                    (),
                    (),
                    map:map() !(
                        map:put( ., "regenerate-summary", fn:true() ),
                        map:put( ., "regenerate-eligibilities", fn:false() ),
                        map:put( ., "flexrep", fn:false() ),
                        .
                    ),
                    map:map() !(
                        map:put( ., "regenerate-summary", fn:true() ),
                        map:put( ., "regenerate-eligibilities", fn:false() ),
                        map:put( ., "flexrep", fn:false() ),
                        map:put( ., "increment-version", fn:true() ),
                        .
                    )
            )
        else
            xdmp:log(string-join (("Error: bank Close Fix Script: Can not Save Document",$doc-id,$schmidtVersion,$maxbankVersion),","))
    return xdmp:log("bank Close Fix Script Processed for docid:" ||$URI||" Max bank Ver:"||$maxbankVersion||" schmidt Close Version:"||$schmidtVersion)
};

(: Main program  :)
(: Enter a comma separated list of documentid's in the ids field:)
let $docids :=("2001")
let $parameterMap := local:parameters()
return for $docid in $docids
(: Get the versions to perform the merge and a close :) let $maxbankRecordValue :=Iocal:maxSourceTypeVersion($docid,map:get(SparameterMap,"banklmap:get(SparameterMap, pen"))

let $maxschmidtRecordValue :=local:maxSourceTypeVersion($docid,map:get($parameterMap,"schmidt"),map:get(SparameterMap,"closec "))
let $maxVersionRecordValue :=local:maxVersion($docid)
(: Construct the liRl's:)
let $bankVersion := "/ingest/documentversions""|| $docid"||$maxbankRecordValue || ".xml"
let $schmidtVersion := "/ingest/documentversions" || $docid || "/"||$maxschmidtRecordValue ||".xml"
let $maxVersion := "/ingest/documentversions" || $docid ||"/"|| $maxVersionRecordValue || ".xml"
(: let $ret:=local:testMerge($docid,$maxbankRecordValue,$maxschmidtRecordValue ,$parameterMap):)
let $doc-update:=local:documentMerge($docid,$maxbankRecordValue,$maxschmidtRecordValue,$parameterMap)
let $saveStatus := local:documentSave($doc-update)
return ($ret)


