(: JP Schmidt 12/2019 :)
        (:
        Pull in the XSL namespace.
        Template to test conversion
        :)

        import module namespace patcdoc = "http://proteusadv.com/patc-documents" at "/ext/patc/lib/patc-documents.xqy";

        declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
        declare namespace account    = "http://proteusadv.com/patc/account/1.0";
        declare namespace meta     = "http://proteusadv.com/patc/metadata/1.0";
        declare namespace summ     = "http://proteusadv.com/patc/summary/1.0";
        declare namespace src      = "http://proteusadv.com/patc/original/1.0";
        declare namespace patc      = "http://proteusadv.com/patc/1.0";
        declare namespace wf       = "http://proteusadv.com/patc/workflow/1.0";
        declare namespace c        = "http://proteusadv.com/patc/common/1.0";
        declare namespace dd       = "http://proteusadv.com/patc/destdoc/1.0";
        declare namespace acct     = "http://proteusadv.com/patc/account/1.0";

        let $initial-doc:=doc("/workingdoc/accountversions/28754/1.xml")


        let $stylesheet as element(xsl:stylesheet) :=
<xsl:stylesheet
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="http://proteusadv.com/patc/metadata/1.0"
        xmlns:account="http://proteusadv.com/patc/account/1.0"
        xmlns:c="http://proteusadv.com/patc/common/1.0"
        xmlns:patc="http://proteusadv.com/patc/1.0"
        xmlns:ism="urn:us:gov:ic:ism:v2"
        xmlns:summ="http://proteusadv.com/patc/summary/1.0"
        xmlns:acct="http://proteusadv.com/patc/account/1.0"
        xmlns:src="http://proteusadv.com/patc/original/1.0"
        version="2.0"
        exclude-result-prefixes="#all">

    <xsl:output method="xml" encoding="UTF-8" indent="no"/>

    <xsl:variable name="investtype"
                  select="/patc:patcRecord/patc:patcBody/account:accountOriginal/account:investigationType/c:value/text()"/>
    <xsl:variable name="opendate"
                  select="/patc:patcRecord/patc:patcBody/account:accountOriginal/account:OpenDateList/account:OpenDate/c:value/text()"/>
    <xsl:variable name="number"
                  select="/patc:patcRecord/patc:patcBody/account:accountOriginal/account:Support/c:systemofrecordDbCheck/c:systemIdentifierList/c:systemIdentifier/c:identifierValue/c:value/text()"/>
    <xsl:variable name="id" select="/patc:patcRecord/patc:patcBody/account:accountOriginal/src:Id/c:value/text()"/>

    <!-- Identity template, copies all content by default-->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/patc:patcRecord/patc:patcBody/account:accountOriginal/account:Support">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <account:systemofrecordList>
                <xsl:apply-templates select="node()"/>
            </account:systemofrecordList>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="c:systemofrecordDbCheck">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>

            <c:investigationType originalSystem="SYSTEMOFRECORD" owner="Systemofrecord" itemState="NEW">
                <xsl:attribute name="originalNumber">
                    <xsl:value-of select="$number"/>
                </xsl:attribute>
                <c:value c:srcid="bofa" c:country="USA">
                    <xsl:value-of select="$investtype"/>
                </c:value>
            </c:investigationType>
            <!-- Systemofrecord Date info-->
            <c:openDate owner="Systemofrecord" originalSystem="SYSTEMOFRECORD">
                <xsl:attribute name="originalNumber">
                    <xsl:value-of select="$number"/>
                </xsl:attribute>
                <c:value c:srcid="bofa" c:country="USA">
                    <xsl:value-of select="$opendate"/>
                </c:value>
            </c:openDate>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/patc:patcRecord/patc:patcBody/account:accountOriginal/acct:account/acct:systemIdentifierList">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:for-each
                    select="/patc:patcRecord/patc:patcBody/account:accountOriginal/acct:account/acct:identity/acct:BANK_ID/text()">

                <c:systemIdentifier owner="Systemofrecord" valid="false" editable="false" c:srcid="bofa"
                                    c:country="USA">
                    <c:context originalSystem="SYSTEMOFRECORD">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="bofa" c:country="USA">SYSTEMOFRECORD</c:value>
                    </c:context>
                    <c:identifierName originalSystem="SYSTEMOFRECORD" owner="CAPONE">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="bofa" c:country="USA">CAPONE_ID</c:value>
                    </c:identifierName>
                    <c:identifierValue originalSystem="SYSTEMOFRECORD" owner="Systemofrecord">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="bofa" c:country="USA">
                            <xsl:value-of select="."/>
                        </c:value>
                    </c:identifierValue>
                </c:systemIdentifier>
            </xsl:for-each>

            <xsl:for-each
                    select="/patc:patcRecord/patc:patcBody/account:accountOriginal/acct:account/acct:identity/acct:identificationList/acct:identification[acct:type/c:value='BANK ID']/acct:identificationIdentifier/c:value/text()">
                <c:systemIdentifier owner="Systemofrecord" valid="false" editable="false">
                    <c:context originalSystem="SYSTEMOFRECORD">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="BOFA" c:country="USA">SYSTEMOFRECORD</c:value>
                    </c:context>
                    <c:identifierName originalSystem="SYSTEMOFRECORD" owner="TSC">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="BOFA" c:country="USA">FIN</c:value>
                    </c:identifierName>
                    <c:identifierValue originalSystem="SYSTEMOFRECORD" owner="Systemofrecord">
                        <xsl:attribute name="originalNumber">
                            <xsl:value-of select="$id"/>
                        </xsl:attribute>
                        <c:value c:srcid="BOFA" c:country="USA">
                            <xsl:value-of select="."/>
                        </c:value>
                    </c:identifierValue>
                </c:systemIdentifier>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>

        (: Create the revised document. :)
        let $revised-document as document-node() := xdmp:xslt-eval(
        $stylesheet,
        $initial-doc
        )

        (:return ($initial-doc//account:Support, $revised-document//account:Support):)
        return ($revised-document)
