<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

    <!-- Converts a German month name (param 'monthname')
         into a zero-padded two-digit month number.
    -->
    <xsl:template name="monthname2int_padded_de">
        <xsl:param name="monthname" select="'(unset)'" />

        <xsl:choose>
            <xsl:when test="$monthname = 'Januar'">01</xsl:when>
            <xsl:when test="$monthname = 'Februar'">02</xsl:when>
            <xsl:when test="$monthname = 'März'">03</xsl:when>
            <xsl:when test="$monthname = 'April'">04</xsl:when>
            <xsl:when test="$monthname = 'Mai'">05</xsl:when>
            <xsl:when test="$monthname = 'Juni'">06</xsl:when>
            <xsl:when test="$monthname = 'Juli'">07</xsl:when>
            <xsl:when test="$monthname = 'August'">08</xsl:when>
            <xsl:when test="$monthname = 'September'">09</xsl:when>
            <xsl:when test="$monthname = 'Oktober'">10</xsl:when>
            <xsl:when test="$monthname = 'November'">11</xsl:when>
            <xsl:when test="$monthname = 'Dezember'">12</xsl:when>

            <xsl:otherwise>
                <xsl:message terminate="yes">
                    ERROR in template monthname2int_padded_de:
                    Unhandled month name "<xsl:value-of select="$monthname" />"!
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
