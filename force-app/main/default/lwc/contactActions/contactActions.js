import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import candidateCreate from "@salesforce/apex/CVTransformerApi.candidateCreate";
import configurationGet from "@salesforce/apex/CVTransformerApi.configurationGet";

export default class ContactActions extends LightningElement {
  @api recordId;
  api_key;
  candidate_id;
  error;
  organization_id;

  @wire(configurationGet, { contactId: "$recordId" })
  wiredData({ error, data }) {
    console.log(error, data);
    if (data) {
      this.api_key = data.api_key__c;
      this.organization_id = data.name;
      this.error = null;
    } else if (error) {
      this.error = error;
      this.api_key = null;
      this.organization_id = null;
    }
  }

  apiKeySave = (event) => {
    // Form event
    event.preventDefault();
    console.log(event);
  };

  handleApiCall = () => {
    candidateCreate({ contactId: this.recordId })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "API triggered successfully",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  };
}
