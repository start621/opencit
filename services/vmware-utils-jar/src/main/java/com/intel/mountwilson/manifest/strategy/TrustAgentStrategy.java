package com.intel.mountwilson.manifest.strategy;

import java.util.HashMap;

import javax.persistence.EntityManagerFactory;

import com.intel.mountwilson.as.common.ASException;
import com.intel.mtwilson.as.controller.TblMleJpaController;
import com.intel.mtwilson.as.data.TblHosts;
import com.intel.mtwilson.as.data.TblMle;
import com.intel.mountwilson.manifest.IManifestStrategy;
import com.intel.mountwilson.manifest.data.IManifest;
import com.intel.mountwilson.manifest.helper.TAHelper;
import com.intel.mtwilson.datatypes.ErrorCode;

/**
 * XXX needs to move to a trust-agent specific package
 */
public class TrustAgentStrategy extends TAHelper implements IManifestStrategy {

	
	public TrustAgentStrategy(EntityManagerFactory entityManagerFactory)
			 {
		super(entityManagerFactory);
	}

        // BUG #497 the Map<String,? extends IManifest> needs to be replaced with the new PcrManifest model object.
	@Override
	public HashMap<String, ? extends IManifest> getManifest(TblHosts tblHosts) {
		
		
		String pcrList = getPcrList(tblHosts);
		
		return getQuoteInformationForHost(tblHosts.getIPAddress(), pcrList, tblHosts.getName(), tblHosts.getPort());
		
		
	}
	
    private String getPcrList(TblHosts tblHosts) {
        
        // Get the Bios MLE without accessing cache
        
        TblMle biosMle = new TblMleJpaController(getEntityManagerFactory()).findMleById(tblHosts.getBiosMleId().getId());
        
        String biosPcrList = biosMle.getRequiredManifestList();

        if (biosPcrList.isEmpty()) {
            throw new ASException(ErrorCode.AS_MISSING_MLE_REQD_MANIFEST_LIST, tblHosts.getBiosMleId().getName(), tblHosts.getBiosMleId().getVersion());
        }

        // Get the Vmm MLE without accessing cache
        TblMle vmmMle = new TblMleJpaController(getEntityManagerFactory()).findMleById(tblHosts.getVmmMleId().getId());

        String vmmPcrList = vmmMle.getRequiredManifestList();

        if (vmmPcrList == null || vmmPcrList.isEmpty()) {
            throw new ASException(ErrorCode.AS_MISSING_MLE_REQD_MANIFEST_LIST, tblHosts.getVmmMleId().getName(), tblHosts.getVmmMleId().getVersion());
        }

        return biosPcrList + "," + vmmPcrList;

    }

}
