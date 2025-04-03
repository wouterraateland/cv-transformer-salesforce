import { LightningElement, api, wire, track } from "lwc";
import getRelatedContentVersions from "@salesforce/apex/CVTransformerApi.getRelatedContentVersions";

export default class ContentVersionDropdown extends LightningElement {
  @api recordId;
  @track contentVersions = [];

  @wire(getRelatedContentVersions, { recordId: "$recordId" })
  wiredContentVersions({ error, data }) {
    if (data)
      this.contentVersions = data.map((cv) => ({
        label: cv.Title,
        value: cv.Id
      }));
    else if (error) console.error("Error fetching ContentVersions:", error);
  }

  onSelect(event) {
    this.dispatchEvent(
      new CustomEvent("select", { detail: event.detail.value })
    );
  }
}
