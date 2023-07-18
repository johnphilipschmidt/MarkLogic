
(:
Phil Schmidt
COVID Development for when we can go back to work
:)
xquery version "1.0-ml";
declare namespace summ="http://proteus.com/patc/summary/1.0";
declare variable $MAPNAME as xs:string  := "5356map";

declare variable $MAP := xdmp:get-server-field($MAPNAME);

(: Explicitly disable function mapping. :)
declare option xdmp:mapping "false";

(: Grab the XPath filename.:)
declare variable $FILENAME as xs:string? external := ();

(: Ensure that we are not using the old serverfield :)
let $_:=
    if(fn:exists(xdmp:get-server-field($MAPNAME))) then
        xdmp:set-server-field($MAPNAME, ())
    else
        ()


(: Grab the XPath rows. :)
let $csv-rows as xs:string* :=
    if(xdmp:filesystem-file-exists($FILENAME)) then
        fn:tokenize(xdmp:filesystem-file($FILENAME), "\n")
    else
        fn:error(xs:QName("ERROR"), "File Not found:"||$FILENAME)

(: Initialize the server field. :)
let $SERVER-MAPNAME :=
    if (fn:exists($MAPNAME)) then
    (: Create the map of XPaths. :)
        let $map as map:map := map:map()
        let $_ :=
            (: Now update the map. :)
            for $row as xs:string in $csv-rows
            (: Skip empty rows. :)
            where fn:string-length($row) gt 0
            (: Store the row contents in the map. :)
            return
                map:put($map, $row, "X")
        (: Store the created map in the server field. :)
        return xdmp:set-server-field($MAPNAME, $map)
    else
        fn:error(xs:QName("ERROR"), "Map not created:"||$MAPNAME)

(:Process only the accounts listed in the map:)
let $uris :=
    cts:uris
    (
            (),(),

            cts:and-query
            (
                    (
                        cts:or-query
                        (
                                (
                                    cts:directory-query("/account/accountNumber/","infinity"),
                                    cts:directory-query("/account/accountNumberversions/","infinity")
                                )
                        ),
                        cts:element-range-query(xs:QName("summ:ID"), "=", (map:keys($SERVER-MAPNAME)! xs:unsignedLong(.)))
                    )
            )

    )
return (count($uris),$uris)

