<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:se="http://www.syntext.com/XSL/Format-1.0"
                xmlns:xse="http://www.syntext.com/Extensions/XSLT-1.0"
                version='1.0'>


<!-- USER SPECIFIC DECLARED VALUES  (change as needed) -->

<xsl:variable name="copyright">Copyright 2006</xsl:variable>

<xsl:param name="HIDE-MAP-TOPICMETA"
           xse:type="string" 
           xse:annotation="Do not show descriptions for topicrefs (ditamap)"
           select="'no'" />

<xsl:param name="SHOW-RESOLVED-TOPICREFS"
           xse:type="string" 
           xse:annotation="Show all topicrefs resolved (ditamap)"
           select="'no'" />

<xsl:param name="SHOW-MAP-DESCRIPTIONS"
           xse:type="string" 
           xse:annotation="Show descriptions for topicrefs (ditamap)"
           select="'no'" />

<!-- /Lang = default language parameter  -->
<xsl:param name="Lang"
           xse:type="string"
           xse:annotation="Default language (for generated text)"
           select="'en-us'"/> 

<!-- "GLOBAL" DECLARATIONS -->

<xsl:variable name="img-path"></xsl:variable> <!-- this will be specific to your delivery tree! -->
<xsl:variable name="dflt-ext">.jpg</xsl:variable> <!-- this sets whatever your preferred extension is for your graphics -->
                                                  <!-- For Antenna House, override to ".jpg" -->

<!-- Filler for A-name anchors (empty links)-->
<xsl:variable name="afill"></xsl:variable>

<!-- Filler for empty table entries -->
<xsl:variable name="efill">.</xsl:variable>

<!-- Setup for translation/localization -->
<xsl:variable name="StringFile" select="document('strings.xml')"/>
<xsl:variable name="PrimaryLang" select="substring-before($Lang,'-')"/>


<!-- DEFAULT VALUES FOR EXTERNALLY MODIFIABLE PARAMETERS -->

<!-- /CSS = user's CSS filename parameter ('')-->
<xsl:param name="default-css" select="'common.css'"/>
<xsl:param name="CSS" select="''"/>

<!-- /CSSPATH = default CSS path parameter (null)-->
<xsl:param name="CSSPATH" select="''"/>

<!-- /IP = default image path parameter (null)-->
<xsl:param name="IP" select="''"/>

<!-- /ARTLBL = default "output artwork filenames" processing parameter ('no')-->
<xsl:param name="ARTLBL" select="'no'"/><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<!-- /OUTEXT = default "output extension" processing parameter ('pdf')-->
<xsl:param name="OUTEXT" select="'pdf'"/><!-- "pdf" and "ps" are valid values for FO -->

<!-- /WORKDIR = the working directory that contains the document being transformed.
     Needed as a directory prefix for the @conref and @href "document()" function calls.
     default is '')-->
<xsl:param name="WORKDIR" select="''"/>

<!-- /FILENAME = the file name (file name and extension only - no path) of the document being transformed.
     Needed to help with debugging.
     default is 'myfile.xml')-->
<xsl:param name="FILENAME" select="'myfile.xml'"/>


<!-- some conditional views that can be selected within the stylesheet -->

<!-- /DBG = Debug mode - enables XSL debugging xsl-messages. (default is 'no')-->
<xsl:param name="DBG"
           xse:type="string" 
           xse:annotation="Enable Debug messages to go to message queue"
           select="'no'"/><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<!-- /INDEXSHOW = default "hide index entries" processing parameter ('no' = hide them)-->
<xsl:param name="INDEXSHOW"
           xse:type="string" 
           xse:annotation="Show/Hide index entry elements"
           select="'yes'" /><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<!-- /SHOWPROLOG = default "show prolog" processing parameter ('no' = hide them)-->
<xsl:param name="SHOWPROLOG"
           xse:type="string" 
           xse:annotation="Show/Hide prolog element"
           select="'yes'" /><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<!-- /DRAFT = default "hide draft & cleanup content" processing parameter ('no' = hide them)-->
<xsl:param name="DRAFT"
           xse:type="string" 
           xse:annotation="Show/Hide draft-comment and required-cleanup elements"
           select="'yes'" /><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<!-- /SHOW-CONREF-RESOLVED = default "edit conref" processing parameter ('yes' = render them)-->
<xsl:param name="SHOW-CONREF-RESOLVED"
           xse:type="string" 
           xse:annotation="Editing view for conrefs"
           select="'yes'" /><!-- "no" and "yes" are valid values; non-'yes' is ignored -->

<xsl:param name="body.font.size"
           xse:type="string" 
           xse:annotation="Body font size"
           select="'10pt'"/>

<!-- CONTROL PARAMETERS -->
<!-- offset -->
<xsl:param name="basic-start-indent">32pt</xsl:param>
<xsl:param name="basic-end-indent">24pt</xsl:param>
<xsl:param name="basic-first-indent">44pt</xsl:param>

<xsl:variable name="do-place-ing">no</xsl:variable><!-- values: yes, no (or any not "yes") -->

<!-- ========== FORMATTER DECLARATIONS AND GLOBALS ========== -->

<!-- set up CSS-like attribute sets -->
<!-- tempted to use the shorthand form? if so, beware of "silent overrides" -->

<xsl:attribute-set name="topic" >
  <xsl:attribute name="font-family">Helvetica</xsl:attribute>
  <xsl:attribute name="font-size">10pt</xsl:attribute>
</xsl:attribute-set>

<!-- set up common attributes for all page definitions -->
<xsl:attribute-set name="common-grid">
  <xsl:attribute name="page-width">51pc</xsl:attribute> <!-- A4: 210mm -->
  <xsl:attribute name="page-height">66pc</xsl:attribute> <!-- A4: 297mm -->
  <xsl:attribute name="margin-top">3pc</xsl:attribute>
  <xsl:attribute name="margin-bottom">3pc</xsl:attribute>
  <xsl:attribute name="margin-left">6pc</xsl:attribute>
  <xsl:attribute name="margin-right">6pc</xsl:attribute>
</xsl:attribute-set>

<!-- add line-height for multi-line headings? -->

<xsl:attribute-set name="h0.title" >
  <xsl:attribute name="break-before">page</xsl:attribute>
  <xsl:attribute name="margin-top">0pc</xsl:attribute>
  <xsl:attribute name="margin-bottom">1.4pc</xsl:attribute>
  <xsl:attribute name="font-size">16pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="topictitle1" >
  <xsl:attribute name="break-before">page</xsl:attribute>
  <xsl:attribute name="margin-top">0pc</xsl:attribute>
  <xsl:attribute name="margin-bottom">1.4pc</xsl:attribute>
  <xsl:attribute name="font-size">16pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="topictitle2" >
  <xsl:attribute name="margin-top">1pc</xsl:attribute>
  <xsl:attribute name="margin-bottom">5pt</xsl:attribute>
  <xsl:attribute name="font-size">14pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="topictitle3" >
  <xsl:attribute name="margin-top">1pc</xsl:attribute>
  <xsl:attribute name="margin-bottom">2pt</xsl:attribute>
  <xsl:attribute name="font-size">14pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="topictitle4" >
  <xsl:attribute name="font-size">9pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
  <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
</xsl:attribute-set>


<xsl:attribute-set name="topictitle5" >
  <xsl:attribute name="font-size">11pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="topictitle6" >
  <xsl:attribute name="font-size">11pt</xsl:attribute>
  <xsl:attribute name="font-style">italic</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
</xsl:attribute-set>


<xsl:attribute-set name="section.title" >
  <xsl:attribute name="space-before">1em</xsl:attribute>
  <xsl:attribute name="color">black</xsl:attribute>
  <xsl:attribute name="font-size">11pt</xsl:attribute>
  <xsl:attribute name="font-weight">bold</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="unused.section.title">
  <xsl:attribute name="space-before">1em</xsl:attribute>
  <xsl:attribute name="space-before.precedence">1</xsl:attribute>
  <xsl:attribute name="space-after">1em</xsl:attribute>
  <xsl:attribute name="keep-with-next.within-column">always</xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute>
</xsl:attribute-set>


<!-- p-->
<xsl:attribute-set name="p">
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="space-before">0.6em</xsl:attribute>
  <xsl:attribute name="space-after">0.6em</xsl:attribute>
  <xsl:attribute name="padding-bottom">0.4em</xsl:attribute>
  <!--xsl:attribute name="text-align">justify</xsl:attribute-->
</xsl:attribute-set>

<!-- p-->
<xsl:attribute-set name="top.p">
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="space-before">0.6em</xsl:attribute>
  <xsl:attribute name="space-after">0.6em</xsl:attribute>
  <xsl:attribute name="padding-bottom">0.4em</xsl:attribute>
  <!--xsl:attribute name="text-align">justify</xsl:attribute-->
</xsl:attribute-set>

<!-- p-->
<xsl:attribute-set name="divlike.p">
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="space-before">0em</xsl:attribute>
  <xsl:attribute name="space-after">0.6em</xsl:attribute>
  <xsl:attribute name="padding-bottom">0.4em</xsl:attribute>
  <!--xsl:attribute name="text-align">justify</xsl:attribute-->
</xsl:attribute-set>

<xsl:attribute-set name="lq" >
  <!--xsl:attribute name="background-color">antiquewhite</xsl:attribute-->
  <!--xsl:attribute name="font-style">italic</xsl:attribute-->
  <xsl:attribute name="space-before">10pt</xsl:attribute>
  <xsl:attribute name="space-after">10pt</xsl:attribute>
  <xsl:attribute name="padding-left">2pt</xsl:attribute>
  <xsl:attribute name="padding-bottom">0.4em</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/> + 20pt</xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/> + 20pt</xsl:attribute>
  <xsl:attribute name="text-align">left</xsl:attribute>
  <xsl:attribute name="border-style">solid</xsl:attribute>
  <xsl:attribute name="border-color">black</xsl:attribute>
  <xsl:attribute name="border-width">thin</xsl:attribute>
</xsl:attribute-set>


<!-- footnote-->
<xsl:attribute-set name="footnote">
  <xsl:attribute name="font-family">Helvetica</xsl:attribute>
  <xsl:attribute name="font-size">8pt</xsl:attribute>
  <xsl:attribute name="line-height">10pt</xsl:attribute>
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="space-before">0em</xsl:attribute>
  <xsl:attribute name="space-after">0.6em</xsl:attribute>
  <xsl:attribute name="start-indent">0in</xsl:attribute>
  <!--xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute-->
  <xsl:attribute name="text-align">justify</xsl:attribute>
</xsl:attribute-set>


<!-- note -->
<xsl:attribute-set name="note" >
  <xsl:attribute name="background-color">antiquewhite</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute>
  <xsl:attribute name="padding-bottom">0.4em</xsl:attribute>
</xsl:attribute-set>


<!-- ul-->
<xsl:attribute-set name="ul">
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="padding-top">0.4em</xsl:attribute>
  <xsl:attribute name="space-before">0.6em</xsl:attribute>
  <xsl:attribute name="space-after">0.6em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="dd.p">
  <xsl:attribute name="start-indent">0em</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="dd.cell" >
  <xsl:attribute name="space-before">0.3em</xsl:attribute>
  <xsl:attribute name="space-after">0.5em</xsl:attribute>
  <xsl:attribute name="start-indent">2em</xsl:attribute>
  <!--xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/> + 0.5em</xsl:attribute-->
</xsl:attribute-set>


<xsl:attribute-set name="dt" >
  <xsl:attribute name="font-weight">bold</xsl:attribute>
  <xsl:attribute name="text-indent">0em</xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="dd" >
  <xsl:attribute name="space-before">0.3em</xsl:attribute>
  <xsl:attribute name="space-after">0.5em</xsl:attribute>
  <xsl:attribute name="start-indent">6pc</xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="pre">
  <!--xsl:attribute name="start-indent">inherit</xsl:attribute-->
  <xsl:attribute name="space-before">1.2em</xsl:attribute>
  <xsl:attribute name="space-after">0.8em</xsl:attribute>
  <xsl:attribute name="white-space-treatment">preserve</xsl:attribute>
  <xsl:attribute name="white-space-collapse">false</xsl:attribute>
  <xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
  <xsl:attribute name="background-color">#f0f0f0</xsl:attribute>
  <xsl:attribute name="font-family">Courier</xsl:attribute>
  <xsl:attribute name="line-height">106%</xsl:attribute>
  <!--xsl:attribute name="font-size">8pt</xsl:attribute-->
</xsl:attribute-set>

<xsl:attribute-set name="lines">
  <xsl:attribute name="space-before">0.8em</xsl:attribute>
  <xsl:attribute name="space-after">0.8em</xsl:attribute>
  <xsl:attribute name="white-space-treatment">preserve</xsl:attribute>
  <xsl:attribute name="white-space-collapse">false</xsl:attribute>
  <xsl:attribute name="linefeed-treatment">preserve</xsl:attribute>
  <xsl:attribute name="wrap-option">wrap</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="fig">
  <xsl:attribute name="space-before">0.8em</xsl:attribute>
  <xsl:attribute name="space-after">0.8em</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
  <!--xsl:attribute name="font-size">10pt</xsl:attribute-->
  <xsl:attribute name="margin-left">+6pt</xsl:attribute>
</xsl:attribute-set>


<xsl:attribute-set name="figure.title" > <!-- unused-->
  <xsl:attribute name="text-align">center</xsl:attribute>
  <xsl:attribute name="space-before">3pt</xsl:attribute>
  <xsl:attribute name="start-indent"><xsl:value-of select="$basic-start-indent"/></xsl:attribute>
  <xsl:attribute name="end-indent"><xsl:value-of select="$basic-end-indent"/></xsl:attribute>
</xsl:attribute-set>


<!-- frame properties used by fig, table -->

<!-- separate the frame attributes into here; include them conditionally -->
<xsl:attribute-set name="frameall">
  <xsl:attribute name="border-style">solid</xsl:attribute>
  <xsl:attribute name="border-width">1pt</xsl:attribute>
  <xsl:attribute name="border-color">black</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="frametop">
  <xsl:attribute name="border-top-style">solid</xsl:attribute>
  <xsl:attribute name="border-top-width">1pt</xsl:attribute>
  <xsl:attribute name="border-top-color">black</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="framebottom">
  <xsl:attribute name="border-bottom-style">solid</xsl:attribute>
  <xsl:attribute name="border-bottom-width">1pt</xsl:attribute>
  <xsl:attribute name="border-bottom-color">black</xsl:attribute>
</xsl:attribute-set>



</xsl:stylesheet>
