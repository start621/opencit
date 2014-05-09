/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.intel.mtwilson.tag.client.jaxrs;

import com.intel.dcsg.cpg.io.UUID;

/**
 *
 * @author ssbangal
 */
public class ApproveTagCertificateRequest {
        
    /**
     * This function provided the certificate request ID, and the certificate associated to it (provided
     * by an external CA), stores the certificate details in the database and updates the request status to
     * completed. Here it is assumed that the external CA would have added the required attributes in the
     * certificate it generated.
     * <p>
     * <i><u>Roles Needed:</u></i> AssetManagement
     * <p>
     * <i><u>Content type returned:</u></i>JSON/XML<br>
     * <p>
     * <i><u>Sample REST API call :</u></i><br>
     * <i>Method Type: POST</i><br>
     * https://192.168.1.101:8181/mtwilson/v2/approve_tag_certificate_request
     * <p>
     * <i>Sample Input</i><br>
     * {"certificate_request_id":"187ec902-c6c6-4dfb-adb4-f240099aa4b0","certificate":"MIIO....ic="}
     * </selection></selections>
     * <p>
     * <i><u>Sample Output:</u></i><br>
     * NA
     * <p>
     * @since Mt.Wilson 2.0
     */
    public byte[] provisionTagCertificate(UUID certificateRequestId, byte[] certificate) {
        return null;
    }
        
}