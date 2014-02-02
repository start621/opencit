/*
 * Copyright (C) 2013 Intel Corporation
 * All rights reserved.
 */
package com.intel.mtwilson.jersey;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.intel.dcsg.cpg.io.UUID;
import java.net.URL;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
//import org.codehaus.jackson.map.annotate.JsonSerialize;

/**
 *
 * @author jbuhacoff
 */
//@JsonSerialize(include=JsonSerialize.Inclusion.NON_EMPTY) // jackson 1.9
@JsonInclude(JsonInclude.Include.NON_EMPTY) // jackson 2.0
public abstract class Document {
    private UUID id;
    private URL href;
    private final HashMap<String,Object> meta = new HashMap<String,Object>();
    private final HashMap<String,Object> links = new HashMap<String,Object>();
    private Date createdOn; // TODO define a jackson formatter for Date objects to use com.intel.dcsg.cpg.iso8601.Iso8601Date 
    private Date modifiedOn;// TODO  define a jackson formatter for Date objects to use com.intel.dcsg.cpg.iso8601.Iso8601Date 
    
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public URL getHref() {
        return href;
    }
    
    public Map<String, Object> getMeta() {
        return meta;
    }

    public Map<String, Object> getLinks() {
        return links;
    }

    public Date getCreatedOn() {
        return createdOn;
    }

    public void setCreatedOn(Date createdOn) {
        this.createdOn = createdOn;
    }

    public Date getModifiedOn() {
        return modifiedOn;
    }

    public void setModifiedOn(Date modifiedOn) {
        this.modifiedOn = modifiedOn;
    }

    
}
