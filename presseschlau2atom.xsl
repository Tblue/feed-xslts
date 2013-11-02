<?xml version="1.0" encoding="utf-8"?>
<!-- See the file COPYING in this distribution
     for details on the license of this file.

    [META]
        SOURCE_URL  http://massengeschmack.tv/presseschlau/
        FEED_NAME   presseschlau.atom
    [/META]
-->

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/2005/Atom"
    version="1.0" exclude-result-prefixes="h">

    <!-- Imports -->
        <xsl:import href="util.xsl" />

    <!-- General settings -->
        <xsl:output indent="yes" encoding="utf-8" />

    <!-- Variables -->
        <!-- WITH a trailing slash! -->
        <xsl:variable name="site_url" select="'http://massengeschmack.tv/presseschlau/'" />
        <xsl:variable name="site_name" select="'Pressesch(l)au'" />

    <!-- Keys -->
        <!-- Select all divs which contain a link to the full episode. -->
        <xsl:key name="episodes" use="'content'"
            match="//h:div[@class='feed']/h:div[
                    h:a[starts-with(@href, '/play/')]
                ]" />

    <!-- Named templates -->
        <!-- Converts a Pressesch(l)au episode title (param 'title')
             into an atom:updated element.
        -->
        <xsl:template name="presseschlau_make_updated">
            <xsl:param name="title" />

            <xsl:if test="$title = ''">
                <xsl:message terminate="yes">
                    <xsl:value-of
                        select="concat(
                            'ERROR in template presseschlau_make_updated: ',
                            'Empty title passed!')" />
                </xsl:message>
            </xsl:if>

            <updated>
                <!-- Year -->
                <xsl:value-of
                    select="concat(
                        '2',
                        substring-after(
                            substring-after(
                                substring-before($title, ' / '),
                                '. '),
                            ' 2'),
                        '-')" />

                <!-- Month -->
                <xsl:call-template name="monthname2int_padded_de">
                    <xsl:with-param name="monthname"
                        select="substring-before(
                                    substring-after($title, '. '),
                                    ' 2')" />
                </xsl:call-template>
                <xsl:value-of select="'-'" />

                <!-- Day -->
                <xsl:number
                    value="substring-before($title, '. ')"
                    format="01" />

                <!-- Time -->
                <xsl:value-of select="concat(
                        'T',
                        substring-after($title, ' / '),
                        '+01:00')" />
            </updated>
        </xsl:template>

    <!-- Matching templates -->
        <!-- Episode description templates -->
            <!-- Ignore episode image. -->
            <xsl:template match="key('episodes', 'content')/h:p/h:img" />

            <!-- Copy everything else. -->
            <xsl:template match="key('episodes', 'content')/h:p//node()">
                <xsl:copy>
                    <xsl:copy-of select="@*" />
                    <xsl:apply-templates />
                </xsl:copy>
            </xsl:template>

        <!-- Root template -->
        <xsl:template match="/">
            <feed>
                <author>
                    <name><xsl:value-of select="$site_name" /></name>
                </author>

                <id>
                    <xsl:value-of select="$site_url" />
                </id>

                <title>
                    <xsl:value-of select="$site_name" />
                </title>

                <!-- rel="via" would fit better, but is not recognized by Tiny Tiny RSS. -->
                <link rel="alternate" href="{$site_url}" />

                <xsl:for-each select="key('episodes', 'content')">
                    <!-- Is this the first valid (i. e. newest) episode? Use its date for
                         the feed's "last updated" element.
                    -->
                    <xsl:if test="position() = 1">
                        <xsl:call-template name="presseschlau_make_updated">
                            <xsl:with-param name="title" select="normalize-space(h:h4/h:small[2])" />
                        </xsl:call-template>
                    </xsl:if> 

                    <entry>
                        <id>
                            <!-- Not an existing URL, but it's unique. -->
                            <xsl:value-of select="concat(
                                    $site_url,
                                    substring(h:a[1]/@href, 2))" />
                        </id>

                        <link rel="alternate" href="http://massengeschmack.tv{h:a[1]/@href}" />

                        <summary type="xhtml">
                            <div xmlns="http://www.w3.org/1999/xhtml">
                                <p>
                                    <a href="http://massengeschmack.tv{h:a[1]/@href}">
                                        <img alt="Preview"
                                            src="http://massengeschmack.tv{h:p[1]/h:img[1]/@src}" />
                                    </a>
                                </p>
                                <p>
                                    <xsl:apply-templates select="h:p/node()" />
                                </p>
                            </div>
                        </summary>

                        <title>
                            <xsl:value-of select="concat(
                                    substring-before(
                                        normalize-space(h:h4),
                                        ' Pressesch(l)au '),
                                    ' vom ',
                                    substring-after(
                                        normalize-space(h:h4),
                                        ' Pressesch(l)au '))" />
                        </title>

                        <xsl:call-template name="presseschlau_make_updated">
                            <xsl:with-param name="title" select="normalize-space(h:h4/h:small[2])" />
                        </xsl:call-template>
                    </entry>
                </xsl:for-each>
            </feed>
        </xsl:template>
</xsl:stylesheet>
