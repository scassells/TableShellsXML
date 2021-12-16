<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:output method="html" indent="yes" encoding="utf-8"
        doctype-system="http://www.w3.org/TR/html4/strict.dtd"
        doctype-public="-//W3C//DTD HTML 4.01//EN" version="4.0"/>
    <xsl:variable name="rootElement" select="/TableShellDef"/>
    <xsl:variable name="shellTitle" select="$rootElement/Header/Title"/>
    <xsl:variable name="populationType" select="$rootElement/Population"/>
    <xsl:variable name="g_columnDefs" select="$rootElement/ColDefs"/>
    <xsl:variable name="g_rowDefs" select="$rootElement/RowDefs"/>
    <xsl:variable name="g_parameterDefOID" select="$g_rowDefs/ParameterRef/@ParamOID"/>
    <xsl:variable name="g_resultGroupDefs" select="$rootElement/ResultGroupDef"/>
    <xsl:variable name="g_resultSubGroupDefs" select="$rootElement/ResultSubGroupDef"/>
    <xsl:variable name="g_resultDefs" select="$rootElement/ResultDef"/>
    <xsl:variable name="g_contentDefs" select="$rootElement/CellContentDef"/>
    <xsl:variable name="g_StatResultDef" select="$rootElement/StatResultDef"/>
    <xsl:variable name="g_itemDefs" select="//ItemDef"/>
    <xsl:variable name="g_codelists" select="//CodeList"/>
    <xsl:variable name="trtVarOID" select="$g_columnDefs/TreatmentVarRef/@ItemOID"/>
    <xsl:variable name="includeTotal" select="$g_columnDefs/TreatmentVarRef/@IncludeTotal"/>
    <xsl:variable name="colHdrResultOID" select="$g_columnDefs/ResultRef/@ResultOID"/>
    <xsl:variable name="colHdrResultDef" select="$rootElement/ResultDef[@OID = $colHdrResultOID]"/>
    <xsl:variable name="nColhdrResults"  select="count($colHdrResultDef/ResultRef)"/>
    <xsl:variable name="trtCodelistOID"
        select="$rootElement/ItemDef[@OID = $trtVarOID]/CodeListRef/@CodeListOID"/>
    <xsl:variable name="trtCodelistSeq"
        select="$rootElement/CodeList[@OID = $trtCodelistOID]/EnumeratedItem"/>
    <xsl:variable name="nTrtCols" select="count($trtCodelistSeq)"/>
    <xsl:variable name="addTotal"
        select="count($rootElement/ColDefs/TreatmentVarRef[@IncludeTotal = 'Yes'])"/>
    
    <!-- TODO: compute the number of columns, add a colspan attribute to the th elements for the shell header-->
    <xsl:variable name="colspan">
        <xsl:if test="$nColhdrResults != 0">
            <xsl:value-of select="format-number($nColhdrResults *( $nTrtCols + $addTotal) + 1, '#')"/>
        </xsl:if>
        <xsl:if test="$nColhdrResults = 0">
            <xsl:value-of select="format-number($nTrtCols + $addTotal + 1,'#')"/>
        </xsl:if></xsl:variable> 

    <xsl:template match="$rootElement">
        <html lang="en">
            <head>
                <title>
                    <xsl:value-of select="$rootElement/@TableOID"/>
                </title>
                <xsl:call-template name="generateCSS"/>
            </head>
            <body>
                <h1>Shell Definition</h1>
                <table>
                    <xsl:call-template name="ShellTitle"/>

                    <xsl:call-template name="ColHdrs"/>
                    <xsl:call-template name="DisplayContent"/>
                </table>

            </body>
        </html>
    </xsl:template>

    <xsl:template name="DisplayContent">
        <xsl:variable name="parameterDef"
            select="$rootElement/ParameterDef[@OID = $g_parameterDefOID]"/>
        <xsl:variable name="startResultNumber" select="$nTrtCols + $addTotal"/>

        <xsl:for-each select="$parameterDef/ItemRef">
            <xsl:variable name="iParam" select="position()"/>
            <xsl:variable name="paramItemOID" select="./@ItemOID"/>
            <xsl:variable name="paramItemDef" select="$g_itemDefs[@OID = $paramItemOID]"/>

            <xsl:variable name="visitVarOID" select="$g_rowDefs/AnalysisTimepointRef/@ItemOID"/>
            <xsl:variable name="visitCLOID"
                select="$g_itemDefs[@OID = $visitVarOID]/CodeListRef/@CodeListOID"/>
            <xsl:variable name="visitCL" select="$g_codelists[@OID = $visitCLOID]"/>
            <tr class="header">
                <th class="ap">
                    <xsl:value-of select="$paramItemDef/@Name"/> (<xsl:value-of
                        select="$paramItemOID"/>) </th>
            </tr>

            <xsl:for-each select="$visitCL/EnumeratedItem">
                <xsl:sort data-type="number" order="ascending" select="@OrderNumber"/>
                <xsl:variable name="iTP" select="position()"/>
                <xsl:variable name="thisTimepoint" select="@CodedValue"/>

                <tr class="header">
                    <!-- Add handling of VIsit Codelist  to exercise both vertical and horizontal layouts-->
                    <th class="ap"><xsl:value-of select="$g_codelists[@OID = $visitCLOID]/@Name"/>
                            (<xsl:value-of select="$thisTimepoint"/>) Codelist info</th>
                </tr>
                
                
                <xsl:variable name="nColResults" select="count($colHdrResultDef/ResultRef)"/>

                

                <xsl:for-each select="$g_rowDefs/ResultGroupRef">
                    <xsl:variable name="resultGroupOID" select="@ResultGroupOID"/>
                    <xsl:variable name="resultGroup"
                        select="$rootElement/ResultGroupDef[@OID = $resultGroupOID]"/>
                    <xsl:variable name="resultContent"
                        select="$g_contentDefs[@ResultGroupOID = $resultGroupOID]"/>
                    <!--  Each ResultGroup has a timepoint, one or more analysis variables and a list of results -->
                    <!-- The RowDef references the timepoint variable. This loop uses the analysis Timepoint variable' codelist to drive the display within each parameter value. This assumes that the Name of the Timepoint in the ResultGroup must match one of the values in the codelist enumeration. -->
                    <!-- For displays where the columns results are nested, at least some of the result groups will have multiple analysis variables.  For now, this code assumes there at most 2. The column header model does not currently depend on which analysis variable appears first.  The first is assumed to the the 'primary' analysis variable or result and the second can be anything.  -->
                    <!-- For each timepoint in the codelist, display the Result group for each analysis Variable in the codelist using OrderNumber.   if the column headers have nested results, make sure one td element is created even when there is onlye one analysis variable.-->
                    <!--   Toggle for Debugging: output timepoint identifier info.  -->
                    <!-- ResultGroup Timeline info relies on a codelist.  THe codelist supports data flow. -->
                    <tr class="header">
                        <th class="ap">Timepoint <xsl:value-of select="$thisTimepoint"/> ResultTimepoint [<xsl:value-of select="$resultGroup/AnalysisTimepoint/@Name"/>] Result Content match <xsl:value-of select="$resultContent/@OID"/> </th>
                    </tr>
                    
                    <xsl:if test="$resultGroup/AnalysisTimepoint/@Name = $thisTimepoint">
                        <tr class="header">
                            <!-- Add handling of VIsit Codelist  to exercise both vertical and horizontal layouts-->
                            <th class="ap">Timepoint <xsl:value-of select="$thisTimepoint"/> </th>
                        </tr>
                        <xsl:variable name="nColhdrResults"
                            select="count($colHdrResultDef/ResultRef)"/>
                        <xsl:variable name="outputRownumTP" select="($iParam -1 + $iTP - 1) * $nColResults"/>

                        <!-- Revise loop so it can be used for either layout type? -->
                        <!-- if there nAvars lt nColhdrResults, output mt cell.  if nAvars is the sam as nColhdr Results output results for each avar -->
                        <xsl:for-each select="$resultGroup/ResultRef">
                            <xsl:variable name="i" select="$outputRownumTP + position()"/>
                            <xsl:variable name="avalList" select="$resultGroup/AnalysisVariable"/>
                            <xsl:variable name="nAvars" select="count($avalList)"/>
                            <tr>

                                <xsl:variable name="thisResultRef" select="."/>
                                <xsl:variable name="resultOID" select="$thisResultRef/@ResultOID"/>
                                <xsl:variable name="resultDef"
                                    select="$g_resultDefs[@OID = $resultOID]"/>

                                <xsl:variable name="nestedResult" select="$resultDef/@IsNested"/>
                                <!--<th>Result OID <xsl:value-of select="$resultOID"/> Nested? <xsl:value-of select="$nestedResult"/></th>-->
                                <xsl:if test="$nestedResult = 'No'">
                                    <xsl:variable name="statResultDef"
                                        select="$resultDef/StatResultDef"/>

                                    <th class="r">
                                        <xsl:value-of select="$statResultDef/ResultLabel"/>
                                    </th>
                                    <xsl:variable name="resFormat" select="$statResultDef/Format"/>
                                    <xsl:for-each select="$trtCodelistSeq">
                                        <xsl:variable name="j" select="position()"/>
                                        <xsl:for-each select="$avalList">
                                            <xsl:variable name="k" select="position()"/>
                                            <xsl:variable name="avalOID" select="@ItemOID"/>
                                            <td>
                                              <!--  <xsl:value-of select="$resFormat"/> (<xsl:value-of
                                                  select="$rootElement/ItemDef[@OID = $avalOID]/@Name"
                                                /> ) -->
                                                <xsl:value-of select="$resFormat"/> {<xsl:value-of select="$i"/>,<xsl:value-of select="$j"/>,<xsl:value-of select="$k"/>}
                                                {R<xsl:value-of select="$startResultNumber + $j"/>} line 157
                                            </td>
                                        </xsl:for-each>
                                        <xsl:if test="$nAvars &lt; $nColhdrResults">
                                            <td class="mt">EMPTY</td>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!-- Handle Total -->
                                    <xsl:if test="$includeTotal = 'Yes'">
                                        <xsl:variable name="iCount" select="$nColhdrResults + $outputRownumTP"/>
                                        <xsl:variable name="jCount" select="count($trtCodelistSeq)"/>
                                        <xsl:for-each select="$avalList">
                                            <xsl:variable name="k" select="position()"/>
                                            <xsl:variable name="avalOID" select="@ItemOID"/>
                                            <td>
                                              <!--  <xsl:value-of select="$resFormat"/>(<xsl:value-of
                                                  select="$rootElement/ItemDef[@OID = $avalOID]/@Name"
                                                /> )-->
                                                <xsl:value-of select="$resFormat"/> {<xsl:value-of select="$iCount"/>,<xsl:value-of select="$jCount"/>,<xsl:value-of select="$k"/>
                                                {R<xsl:value-of select="$startResultNumber +$jCount + $k"/>} line 176
                                            </td>
                                        </xsl:for-each>
                                        
                                        <xsl:if test="$nAvars &lt; $nColhdrResults">
                                            <td class="mt">EMPTY</td>
                                        </xsl:if>
                                    </xsl:if>


                                </xsl:if>
                                <xsl:if test="$nestedResult = 'Yes'">
                                    <!-- 
                         A nested ResultDef will inculde a list of ResultRefs. A non-nested ResultRef will include a StatResult. Each StatResult will include a Name and a format.  
                         There will be a th element for the name and for each element in the trtCodelistSeq and, if applicable, the total column, the fomat will be provided.
                     -->

                                    <th class="r">
                                        <xsl:value-of select="$resultDef/@Name"/>
                                    </th>
                                    <xsl:for-each select="$trtCodelistSeq">
                                        <xsl:variable name="j" select="position()"/>
                                        <xsl:for-each select="$avalList">
                                            <xsl:variable name="k" select="position()"/>
                                            <xsl:variable name="avalOID" select="@ItemOID"/>
                                            <td>
                                                <xsl:for-each select="$resultDef/ResultRef">
                                                    <xsl:variable name="l" select="position()"/>
                                                  <xsl:variable name="nestedResultRefOID"
                                                  select="./@ResultOID"/>
                                                  <xsl:variable name="nestedResultDef"
                                                  select="$g_resultDefs[@OID = $nestedResultRefOID]"/>
                                                  <!--<xsl:value-of select="$nestedResultDef/@OID"/>-->
                                                  <xsl:variable name="statResultDef"
                                                  select="$nestedResultDef/StatResultDef"/>
                                                  <xsl:variable name="resFormat"
                                                        select="$statResultDef/Format"/>
                                                    <xsl:value-of select="$resFormat"/> { 
                                                    <xsl:value-of select="$i"/>, <xsl:value-of select="$j"/>, <xsl:value-of select="$k"/>, <xsl:value-of select="$l"/>}
                                                    R<xsl:value-of select="$nColhdrResults +  $i * $nColResults + $j + $k + $l"/>}
                                                  <!--<xsl:variable name="resFormat"
                                                  select="$statResultDef/Format"/>
                                                  <xsl:value-of select="$resFormat"/> (<xsl:value-of
                                                  select="$rootElement/ItemDef[@OID = $avalOID]/@Name"
                                                  /> )-->
                                                </xsl:for-each>
                                            </td>
                                        </xsl:for-each>
                                        <xsl:if test="$nAvars &lt; $nColhdrResults">
                                            <td class="mt">EMPTY</td>
                                        </xsl:if>

                                    </xsl:for-each>
                                    <!-- Need to handle totals? -->
                                    <xsl:if test="$includeTotal = 'Yes'">
                                        <xsl:variable name="jCount" select="$nColResults"/>

                                        <xsl:for-each select="$avalList">
                                            <xsl:variable name="k" select="position()"/>
                                            <xsl:variable name="avalOID" select="@ItemOID"/>
                                            <td>
                                                <xsl:for-each select="$resultDef/ResultRef">
                                                    <xsl:variable name="l" select="position()"/>
                                                  <xsl:variable name="nestedResultRefOID"
                                                  select="./@ResultOID"/>
                                                  <xsl:variable name="nestedResultDef"
                                                  select="$g_resultDefs[@OID = $nestedResultRefOID]"/>
                                                  <!--<xsl:value-of select="$nestedResultDef/@OID"/>-->
                                                  <xsl:variable name="statResultDef"
                                                  select="$nestedResultDef/StatResultDef"/>
                                                  <!--<xsl:value-of select="$statResultDef"/>-->
                                                  <xsl:variable name="resFormat"
                                                  select="$statResultDef/Format"/>
                                                    <xsl:variable name="resFormat"
                                                        select="$statResultDef/Format"/>
                                                    <xsl:value-of select="$resFormat"/> { 
                                                    <xsl:value-of select="$i"/>, <xsl:value-of select="$jCount"/>, <xsl:value-of select="$k"/>, <xsl:value-of select="$l"/>
                                                    R<xsl:value-of select="$nColhdrResults +  $i * $nColResults + $jCount + $k + $l"/>}
                                                    <!--<xsl:variable name="resFormat"
                                                  select="$statResultDef/Format"/>
                                                  <xsl:value-of select="$resFormat"/> (<xsl:value-of
                                                  select="$rootElement/ItemDef[@OID = $avalOID]/@Name"
                                                  /> )--> </xsl:for-each>
                                            </td>
                                        </xsl:for-each>
                                        <xsl:if test="$nAvars &lt; $nColhdrResults">
                                            <td class="mt">EMPTY</td>
                                        </xsl:if>
                                    </xsl:if>

                                </xsl:if>

                            </tr>
                        </xsl:for-each>
                
                </xsl:if>
                    <xsl:if test="$resultGroup/AnalysisTimepoint/@Name != $thisTimepoint">
                        <tr class="header">
                            <!-- Add handling of VIsit Codelist  to exercise both vertical and horizontal layouts-->
                            <th class="mt">Not this one <xsl:value-of select="$resultContent/AnalysisTimepoint/@Name"/> </th>
                        </tr>
                    </xsl:if>
                </xsl:for-each>

            </xsl:for-each>

        </xsl:for-each>


    </xsl:template>


    <xsl:template name="ShellRows">
        <xsl:for-each select="$g_rowDefs">
            <xsl:variable name="paramInfo" select="./Parameters/@OID"/>
            <xsl:variable name="visitInfo" select="./AnalysisTimepointRef/@ItemOID"/>
            <xsl:variable name="resGroupInfo" select="./ResultGroupRef/@ResultGroupOID"/>
            <xsl:variable name="resultGRP" select="./ResultGroupRef"/>
            <!--TODO:
                For each Parameter or if none, then for generic parameeter, column 0 shows Param item Label and if IncludeUnits is Yes, add units
                
                For each visit.
                Visit label
                StatRows (driven by resGroupref)
                
                Baseline concept only AVAL</xsl:for-each> concept
                If not baseine cycle through other analysis variables
                
                StatLabel, for each pop group and total printout formats. -->

            <xsl:for-each select="$resultGRP/ResultRef">
                <xsl:variable name="resultOID" select="./@ResultOID"/>
                <xsl:variable name="resultDef" select="$g_resultDefs[@OID = $resultOID]"/>
                <xsl:variable name="statOID" select="$resultDef/StatResultRef/@statOID"/>
                <xsl:variable name="statDef" select="$g_StatResultDef[@OID = $statOID]"/>

                <td>
                    <xsl:value-of select="$statDef/ResultLabel"/>
                </td>
                <td>
                    <xsl:value-of select="$statDef/Format"/>
                </td>

            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="ShellTitle">
        <xsl:variable name="shellHeader" select="$rootElement/Header"/>
        <xsl:variable name="studyItemOID" select="$shellHeader/Study/@ItemOID"/>
        <xsl:variable name="studyItemName" select="$rootElement/ItemDef[@OID = $studyItemOID]/@Name"/>
        <xsl:variable name="addTotal"
            select="count($rootElement/ColDefs/TreatmentVarRef[@IncludeTotal = 'Yes'])"/>
        N tx cols <xsl:value-of select="$nTrtCols"/> nColResults <xsl:value-of select="$nColhdrResults"/> --<xsl:value-of select="$colspan"/> colResultOID <xsl:value-of select="$colHdrResultOID"/>
        <tr class="header">
            <th>
                <xsl:attribute name="class" select="'dis'"/>
                <xsl:attribute name="colspan">
                    <xsl:value-of select="$colspan"/></xsl:attribute>
                Study - <xsl:value-of select="$studyItemOID"/>.value
            </th><!--
            <th class="dis" colspan="4"> Study - <xsl:value-of select="$studyItemOID"/>.value </th>-->
            
        </tr>

        <tr class="header"><th>
            <xsl:attribute name="class" select="'dis'"/>
            <xsl:attribute name="colspan">
                <xsl:value-of select="$colspan"/></xsl:attribute>
                <xsl:value-of select="$shellHeader/TitleBlock/@TableNumber"/>
                <xsl:value-of select="$shellHeader/TitleBlock/Description/TranslatedText"/>
            </th>
        </tr>
        <tr class="header">
            <th class="ap" colspan="4" id="popInfo" onmouseover="changeBackground()"
                onmouseout="backToShell()">
                <xsl:value-of select="$shellHeader/TitleBlock/AnalysisPopulationRef/@ApopRef"/>
            </th>
        </tr>

    </xsl:template>
    <xsl:template name="ColHdrs">
        <!-- Update to use Param ItemDef info -->
        <!-- Look up Codelist values and Check whether TreatmentVar has  @IncludeTotal  set to Yes.  -->

        <xsl:variable name="trtvarOID" select="$g_columnDefs/TreatmentVarRef/@ItemOID"/>
        <xsl:variable name="includeTotal" select="$g_columnDefs/TreatmentVarRef/@IncludeTotal"/>
        <xsl:variable name="trtCodelistOID"
            select="$rootElement/ItemDef[@OID = $trtvarOID]/CodeListRef/@CodeListOID"/>
        <!--<xsl:variable name="trtCodelistSeq"
            select="$rootElement/CodeList[@OID = $trtCodelistOID]/EnumeratedItem"/>-->


        <xsl:if test="$colHdrResultDef/@IsNested = 'Yes'">
            <!--  Using a nested Result Def for the change from BL result-->
            <!-- If the column result is nested, count the number of nested results.  -->
            <!-- Use Order number? add empty headers for additional results -->
            <xsl:variable name="nColhdrResults" select="count($colHdrResultDef/ResultRef)"/>

            <tr>
                <th class="hzColHdr">Result@OID is <xsl:value-of select="$colHdrResultOID"/> N
                    results <xsl:value-of select="$nColhdrResults"/></th>
                <xsl:for-each select="$trtCodelistSeq">
                    <xsl:variable name="trtName" select="./@CodedValue"/>
                    <th class="c">Treatment <em><xsl:value-of select="$trtName"/></em></th>
                    <xsl:if test="$nColhdrResults = 2">
                        <th class="mt">Line 257</th>
                    </xsl:if>
                    <xsl:if test="$nColhdrResults &gt; 2">
                        <th class="niy">TBD</th>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    <th class="c">Total</th>
                </xsl:if>
                <xsl:if test="$nColhdrResults = 2">
                    <th class="mt">line 267</th>
                </xsl:if>
                <xsl:if test="$nColhdrResults &gt; 2">
                    <th class="niy">TBD</th>
                </xsl:if>
            </tr>
            <tr>
                <th class="niy"/>
                <!-- next row just has the pop total -->
                <!--<th class="mt"/>
                <xsl:for-each select="$trtCodelistSeq">
                    <xsl:variable name="trtGrpCount"
                        select="$rootElement/ResultDef[@OID = $colHdrResultOID]/StatResDef/@Name"/>
                    <th class="c"><xsl:value-of select="$trtGrpCount"/></th>
                    <xsl:if test="$nColhdrResults = 1">
                        <th class="mt"/>
                    </xsl:if>
                    <xsl:if test="$nColhdrResults &gt; 1">
                        <th class="niy">TBD</th>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    <xsl:variable name="trtGrpCount"
                        select="$rootElement/ResultDef[@OID = $colHdrResultOID]/StatResDef/@Name"/>
                    <th class="c">trtgroupcount <xsl:value-of select="$trtGrpCount"/></th>
                    <xsl:if test="$nColhdrResults = 1">
                        <th class="mt">1</th>
                    </xsl:if>
                    <xsl:if test="$nColhdrResults &gt; 1">
                        <th class="niy">TBD</th>
                    </xsl:if>
                </xsl:if>-->
            </tr>
            <tr>
                <th class="c">Parameter (Units)</th>
                <xsl:for-each select="$trtCodelistSeq">
                    <xsl:for-each select="$colHdrResultDef/ResultRef">
                        <xsl:variable name="trtHdrResultOID" select="./@ResultOID"/>
                        <xsl:variable name="trtHdrResultName"
                            select="$rootElement/ResultDef[@OID = $trtHdrResultOID]/@Name"/>
                        <th class="c">
                            <xsl:value-of select="$trtHdrResultName"/>
                        </th>
                    </xsl:for-each>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    <xsl:for-each select="$colHdrResultDef/ResultRef">
                        <xsl:variable name="trtHdrResultOID" select="./@ResultOID"/>
                        <xsl:variable name="trtHdrResultName"
                            select="$rootElement/ResultDef[@OID = $trtHdrResultOID]/@Name"/>
                        <th class="c">
                            <xsl:value-of select="$trtHdrResultName"/>
                        </th>
                    </xsl:for-each>
                </xsl:if>
            </tr>
            <tr>
                <xsl:variable name="resultOID"
                    select="$colHdrResultDef/ResultRef[@OrderNumber = '1']/@ResultOID"/>
                <xsl:variable name="resultDef" select="$rootElement/ResultDef[@OID = $resultOID]"/>
                <xsl:variable name="statResultOID" select="$resultDef/StatResultDef/@OID"/>
                <xsl:variable name="statResultDef" select="$resultDef/StatResultDef"/>
                <xsl:variable name="resLabel" select="$statResultDef/ResultLabel"/>
                <xsl:variable name="resFormat" select="$statResultDef/Format"/>
                <th class="c">Visit</th>
                <xsl:for-each select="$trtCodelistSeq">
                    <xsl:variable name="i" select="position()"/>
                    <th class="c">(<xsl:value-of select="$resLabel"/>=<xsl:value-of
                            select="$resFormat"/>) {<xsl:value-of select="$i"/>}</th>
                    <xsl:if test="$nColhdrResults = 2">
                        <th class="mt"/>
                    </xsl:if>
                    <xsl:if test="$nColhdrResults &gt; 2">
                        <th class="niy"/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    
                    <th class="c">(<xsl:value-of select="$resLabel"/>=<xsl:value-of
                            select="$resFormat"/>) {<xsl:value-of select="$nColhdrResults + 1"/>}</th>
                    <xsl:if test="$nColhdrResults = 2">
                        <th class="mt"/>
                    </xsl:if>
                    <xsl:if test="$nColhdrResults &gt; 2">
                        <th class="niy"/>
                    </xsl:if>
                </xsl:if>
            </tr>
        </xsl:if>
        <xsl:if test="$colHdrResultDef/@IsNested = 'No'">
            <!-- <xsl:variable name="resultOID" select="$colHdrResultDef/@OID"/>
            <xsl:variable name="resultDef" select="$rootElement/ResultDef[@OID = $resultOID]"/>-->
            <xsl:variable name="statResultOID" select="$colHdrResultDef/StatResultDef/@OID"/>
            <xsl:variable name="statResultDef" select="$colHdrResultDef/StatResultDef"/>
            <xsl:variable name="resLabel" select="$statResultDef/ResultLabel"/>
            <xsl:variable name="resFormat" select="$statResultDef/Format"/>
            <tr>
                <!--<th>Parameter (Units) TxVarOID <xsl:value-of select="$trtvarOID"/> TrtCL <xsl:value-of select="$trtCodelistOID"/> #Tx values <xsl:value-of select="count($trtCodelistSeq)"/></th>-->
                <th class="c">Parameter (Units)</th>
                <xsl:for-each select="$trtCodelistSeq">
                    <xsl:variable name="trtName" select="./@CodedValue"/>
                    <th class="c">Treatment <em><xsl:value-of select="$trtName"/></em></th>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    <th class="c">Total</th>
                </xsl:if>
            </tr>
            <tr>
                <th class="c">Visit</th>
                <xsl:for-each select="$trtCodelistSeq">
                    <th class="c">(<xsl:value-of select="$resLabel"/>=<xsl:value-of
                            select="$resFormat"/>)</th>
                </xsl:for-each>
                <xsl:if test="$includeTotal = 'Yes'">
                    <th class="c">(<xsl:value-of select="$resLabel"/>=<xsl:value-of
                            select="$resFormat"/>)</th>
                </xsl:if>
            </tr>
        </xsl:if>

    </xsl:template>
    <xsl:template name="generateCSS">
        <style type="text/css">
            body {
                background-color: #FFFFFF;
                font-family: Verdana, Arial, Helvetica, sans-serif;
                font-size: 62.5%;
                margin: 0;
                padding: 30px;
            }
            table {
                table-layout: auto;
                }
            table tr.header {
            background-color: #ffffff;
                font-weight: bold;
                border: 1px #7b64ff;
                column-span: <xsl:value-of select="$colspan"/>; 
            }
            table caption {
                border: 0px;
                left: 20px;
                font-size: 1.4em;
                font-weight: bolder;
                color: #696969;
                margin: 10px auto;
                text-align: left;
            }
            
            table th.dis {
                font-weight: bold;
                background-color: #ffffff;
                vertical-align: top;
                text-align: center;
                padding: 5px;
                border: 1px solid #7b64ff;
                font-size: 1.3em;
                column-span: 4; 
                
            }
            table th.mt {
                background-color: #a4dd00;
                }
            table th.niy {
                background-color: #f44e3b;
                }
            table th.ap {
                font-weight: bold;
                background-color: #ffffff;
                vertical-align: top;
                text-align: center;
                padding: 5px;
                border: 1px solid #fcdc00;
                font-size: 1.3em;
            }
            table th.c {
                font-weight: bold;
                background-color: #ffffff;
                vertical-align: top;
                text-align: left;
                padding: 5px;
                border: 1px solid #a4dd00;
                font-size: 1.3em;
                column-span: 1;
            }
            table th.r {
                font-weight: bold;
                background-color: #ffffff;
                vertical-align: top;
                text-align: left;
                padding: 5px;
                border: 1px solid #fcc400;
                font-size: 1.3em;
                column-span: 1;
            }
            
            table td {
                vertical-align: top;
                padding: 5px;
                border: 1px solid #E19569;
                font-size: 1.2em;
                line-height: 150%;
            }
            }</style>

    </xsl:template>


</xsl:stylesheet>
