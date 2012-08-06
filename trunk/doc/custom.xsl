<?xml version='1.0'?> 
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    version="1.0"> 

    <xsl:import href="/usr/share/sgml/docbook/xsl-stylesheets/fo/docbook.xsl"/> 

    <xsl:template match="processing-instruction('hard-pagebreak')">
        <fo:block break-after='page'/>
     </xsl:template>

    <xsl:param name="draft.mode">no</xsl:param>

    <xsl:attribute-set name="monospace.verbatim.properties">
        <xsl:attribute name="font-family">Monaco</xsl:attribute>
        <xsl:attribute name="font-size">8pt</xsl:attribute>
        <xsl:attribute name="keep-together.within-column">always</xsl:attribute>
    </xsl:attribute-set>

    <xsl:param name="shade.verbatim" select="1"/>

    <xsl:attribute-set name="shade.verbatim.style">
        <xsl:attribute name="background-color">#e0e0e0</xsl:attribute>
        <xsl:attribute name="border-width">0.5pt</xsl:attribute>
        <xsl:attribute name="border-style">solid</xsl:attribute>
        <xsl:attribute name="border-color">#575757</xsl:attribute>
        <xsl:attribute name="padding">3pt</xsl:attribute>
    </xsl:attribute-set>

</xsl:stylesheet>
