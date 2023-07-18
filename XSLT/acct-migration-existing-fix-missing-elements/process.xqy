(: Create the stylesheet to close the data. :)
xquery version "1.0-ml";
import module namespace patcdoc = "http://proteus.com/patc-documents" at "/ext/patc/lib/patc-documents.xqy";

declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
declare namespace acctdoc = "http://proteus.com/patc/acctdoc/1.0";
declare namespace c = "http://proteus.com/patc/common/1.0";
declare namespace acctentity = "http://proteus.com/patc/acct/1.0";

declare variable $URI as xs:string external;


let $initial-doc := doc($URI)
let $stylesheet as element(xsl:stylesheet) :=
    <xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:meta="http://proteus.com/patc/metadata/1.0"
    xmlns:acctdoc="http://proteus.com/patc/acctdoc/1.0"
    xmlns:c="http://proteus.com/patc/common/1.0"
    xmlns:patc="http://proteus.com/patc/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:summ="http://proteus.com/patc/summary/1.0"
    xmlns:acctentity="http://proteus.com/patc/acct/1.0"
    xmlns:src="http://proteus.com/patc/source/1.0"
    exclude-result-prefixes="#all">

        <xsl:output method="xml" encoding="UTF-8" indent="no" />

        <xsl:variable name="investtype" select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctdoc:investigationType/c:value/text()" as="xs:string?" />
        <xsl:variable name="opendate" select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctdoc:fbiAccountOpenDateList/acctdoc:fbiAccountOpenDate/c:value/text()" as="xs:string?" />
        <xsl:variable name="accountnumber">
            <xsl:value-of select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctdoc:accountSupport/acctdoc:bofAAccountList/c:bofAAcctDetail[1]/c:systemIdentifierList/c:systemIdentifier/c:identifierValue/c:value"/>
        </xsl:variable>
        <xsl:variable name="id" select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/src:Id/c:value/text()" as="xs:string?"/>

        <!-- Identity template, copies all content by default-->
        <xsl:template match="@*|node()">
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" />
            </xsl:copy>
        </xsl:template>

        <xsl:template match="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctdoc:accountSupport[not(exists(acctdoc:bofAAccountList))]">
            <acctdoc:accountSupport>
                <xsl:apply-templates select="@*" />
                <acctdoc:bofAAccountList>
                    <xsl:apply-templates select="node()" />
                </acctdoc:bofAAccountList>
            </acctdoc:accountSupport>
        </xsl:template>

        <xsl:template mode="handle-primary-flag" match="c:bofAAcctDetail">
            <xsl:param name="primary" as="xs:boolean"/>
            <c:bofAAcctDetail>
                <xsl:if test="$primary">
                    <xsl:attribute name="primary" select="'true'" />
                </xsl:if>
                <xsl:apply-templates select="@*|node()" />

                <!-- Investigation Type info-->
                <c:investigationType sourceSystem="BOFA" valid="true" owner="BofA" itemState="NEW">
                    <xsl:attribute name="sourceNumber"><xsl:value-of select="$accountnumber"/></xsl:attribute>
                    <c:value ><xsl:value-of select="$investtype"/></c:value>
                </c:investigationType>

                <!-- BofA Date info-->
                <c:openDate owner="BofA" valid="true" sourceSystem="BOFA" >
                    <xsl:attribute name="sourceNumber"><xsl:value-of select="$accountnumber"/></xsl:attribute>
                    <c:value ><xsl:value-of select="$opendate"/></c:value>
                </c:openDate>
            </c:bofAAcctDetail>
        </xsl:template>

        <xsl:template match="c:bofAAcctDetail">
            <xsl:apply-templates mode="handle-primary-flag" select=".">
                <xsl:with-param name="primary" select="(@primary eq 'true') or (fn:not(../c:bofAAcctDetail/@primary eq 'true') and (fn:index-of(../c:bofAAcctDetail, .) eq 1))" as="xs:boolean" />
            </xsl:apply-templates>
        </xsl:template>

        <xsl:template match="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctentity:acct/acctentity:identity/acctentity:systemIdentifierList">
            <acctentity:systemIdentifierList>
                <xsl:apply-templates select="@*|node()" />
                <xsl:for-each select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctentity:acct/acctentity:identity/acctentity:TIDE_ID/text()">
                    <!-- Tide id info-->

                    <c:systemIdentifier owner="BofA" itemState="NO_CHANGE" valid="true" editable="false" >
                        <c:context sourceSystem="CAPONE" >
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$accountnumber"/></xsl:attribute>
                            <c:value >BOFA</c:value>
                        </c:context>
                        <c:identifierName sourceSystem="CAPONE" valid="true"  owner="CAPONE" itemState="NO_CHANGE">
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$accountnumber"/></xsl:attribute>
                            <c:value >TIDE_ID</c:value>
                        </c:identifierName>
                        <c:identifierValue sourceSystem="CAPONE" valid="true" owner="CAPONE" itemState="NO_CHANGE">
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$accountnumber"/></xsl:attribute>
                            <c:value ><xsl:value-of select="."/></c:value>
                        </c:identifierValue>
                    </c:systemIdentifier>
                </xsl:for-each>


                <xsl:for-each select="/patc:patcRecord/patc:patcBody/acctdoc:acctdocSource/acctentity:acct/acctentity:identity/acctentity:identificationList/acctentity:identification[acctentity:type/c:value=ACCOUNT ID']/acctentity:identificationIdentifier/c:value/text()">
                    <c:systemIdentifier owner="BofA" itemState="NO_CHANGE" valid="true" editable="false" >
                        <c:context sourceSystem="BOFA" >
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$id"/></xsl:attribute>
                            <c:value>BOFA</c:value>
                        </c:context>
                        <c:identifierName sourceSystem="BOFA"  valid="true"  owner="CAPONE" itemState="NO_CHANGE">
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$id"/></xsl:attribute>
                            <c:value >FIN</c:value>
                        </c:identifierName>
                        <c:identifierValue sourceSystem="BOFA"  valid="true"  owner="BofA" itemState="NO_CHANGE">
                            <xsl:attribute name="sourceNumber"><xsl:value-of select="$id"/></xsl:attribute>
                            <c:value ><xsl:value-of select="."/></c:value>
                        </c:identifierValue>
                    </c:systemIdentifier>
                </xsl:for-each>

            </acctentity:systemIdentifierList>
        </xsl:template>
    </xsl:stylesheet>

(: Create the revised document. :)
let $revised-document as document-node() := xdmp:xslt-eval(
        $stylesheet,
        $initial-doc
)

return patcdoc:save-document-as-is(
        $URI,
        $revised-document,
        (),
        map:map()! (
            map:put(., "regenerate-summary", fn:true()),
            map:put(., "retain-permissions", fn:true()),
            map:put(., "increment-version", fn:false()),
            .
        )
)
