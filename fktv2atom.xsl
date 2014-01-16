<?xml version="1.0" encoding="utf-8"?>
<!-- See the file COPYING in this distribution
     for details on the license of this file.

    [META]
        SOURCE_URL  http://fernsehkritik.tv/tv-magazin/
        FEED_NAME   fernsehkritik.atom
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
        <xsl:variable name="site_url" select="'http://fernsehkritik.tv/'" />
        <xsl:variable name="site_name" select="'Fernsehkritik.TV'" />

    <!-- Keys -->
        <!-- Select all divs with class "lclmo" that:
             - are children of the big "episode" div
             - have a following sibling with class "lclmi" which contains a link
               to the full episode in its "links" div.
        -->
        <xsl:key name="episodes" use="'title'" match="//h:div[@id='episode']/h:div[
                    contains(@class, 'lclmo') and
                        following-sibling::h:div[contains(@class, 'lclmi')][1]//
                            h:div[@class='links']//h:a[starts-with(@href, '/folge-')]
                ]" />

        <!-- All the "lclmi" divs containing an episode link -->
        <xsl:key name="episodes" use="'content'" match="//h:div[@id='episode']/
                h:div[
                    contains(@class, 'lclmi') and
                    .//h:div[@class='links']//h:a[starts-with(@href, '/folge-')]
                ]" />

    <!-- Named templates -->
        <!-- Converts a Fernsehkritik.TV episode title (param 'title')
             into an atom:updated element.
        -->
        <xsl:template name="fktv_make_updated">
            <xsl:param name="title" />

            <xsl:if test="$title = ''">
                <xsl:message terminate="yes">
                    <xsl:value-of
                        select="concat(
                            'ERROR in template fktv_make_updated: ',
                            'Empty title passed!')" />
                </xsl:message>
            </xsl:if>

            <updated>
                <!-- Year -->
                <xsl:value-of
                    select="concat(
                        '2',
                        substring-after(
                            substring-after($title, '. '),
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
                    value="substring-before(
                        substring-after($title, 'vom '),
                        '.')"
                    format="01" />

                <!-- Time -->
                <xsl:value-of select="'T00:00:00+01:00'" />
            </updated>
        </xsl:template>

    <!-- Matching templates -->
        <!-- Episode description templates -->
            <!-- Strip out useless span tags (but copy its contents!). -->
            <xsl:template match="key('episodes', 'content')//h:li/h:span">
                <xsl:apply-templates />
            </xsl:template>

            <!-- Ignore jump links. -->
            <xsl:template match="key('episodes', 'content')//h:li//
                h:a[starts-with(@class, 'jump')]" />

            <!-- Copy everything else. -->
            <xsl:template match="key('episodes', 'content')//node()">
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

                <!-- rel="via" would fit better, but Tiny Tiny RSS only accepts the feed link if it
                     has rel="alternate". Actually, that's not quite true: It only accepts the feed link
                     if it has NO "rel" attribute at all (which, according to RFC 4287, section 4.2.7.2,
                     is the same as explicitly specifying rel="alternate"). In other words, Tiny Tiny RSS
                     punishes you for saying the unsaid. Oh well.

                     Tiny Tiny RSS _does_ accept ENTRY links with an explicit rel="alternate", though.
                     Crappy parser.
                -->
                <link href="{$site_url}" />

                <xsl:for-each select="key('episodes', 'title')">
                    <!-- Is this the first valid (i. e. newest) episode? Use its date for
                         the feed's "last updated" element.
                    -->
                    <xsl:if test="position() = 1">
                        <xsl:call-template name="fktv_make_updated">
                            <xsl:with-param name="title" select="normalize-space(h:h2/h:a)" />
                        </xsl:call-template>
                    </xsl:if> 

                    <entry>
                        <id>
                            <xsl:value-of select="concat($site_url,
                                                    substring-after(
                                                        h:h2/h:a/@href,
                                                        '../'))" />
                        </id>

                        <link rel="alternate"
                            href="{$site_url}{
                                    substring-after(
                                        h:h2/h:a/@href,
                                        '../')
                                    }Start/" />

                        <summary type="xhtml">
                            <div xmlns="http://www.w3.org/1999/xhtml">
                                <p>
                                    <a href="{$site_url}{
                                                substring-after(
                                                    h:h2/h:a/@href,
                                                    '../')
                                                }Start/">
                                        <img alt="Preview"
                                            src="{$site_url}{substring-after(
                                                    following-sibling::h:div[contains(@class, 'lclmi')][1]//
                                                        h:img[1]/@src,
                                                    '../')}" />
                                    </a>
                                </p>
                                <xsl:apply-templates select="following-sibling::h:div[contains(@class, 'lclmi')][1]//
                                    h:div[@class='desc']/node()" />
                            </div>
                        </summary>

                        <title>
                            <xsl:value-of select="normalize-space(h:h2/h:a)" />
                        </title>

                        <xsl:call-template name="fktv_make_updated">
                            <xsl:with-param name="title" select="normalize-space(h:h2/h:a)" />
                        </xsl:call-template>
                    </entry>
                </xsl:for-each>
            </feed>
        </xsl:template>
</xsl:stylesheet>
