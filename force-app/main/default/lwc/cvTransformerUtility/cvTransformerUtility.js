import { NavigationMixin } from "lightning/navigation";
import {
  getEnclosingUtilityId,
  minimizeUtility
} from "lightning/platformUtilityBarApi";
import { LightningElement } from "lwc";
import iframeTokenGet from "@salesforce/apex/CVTransformerApi.iframeTokenGet";
import locale from "@salesforce/i18n/lang";

export default class CVTransformerUtility extends NavigationMixin(
  LightningElement
) {
  url = null;

  get isLoading() {
    return this.url === null;
  }

  connectedCallback() {
    iframeTokenGet().then((token) => {
      this.url = token
        ? "https://www.cv-transformer.com/salesforce/new-candidate?" +
          new URLSearchParams({ locale, token })
        : "https://www.cv-transformer.com/salesforce/onboard?" +
          new URLSearchParams({ locale });
    });
    this.messageHandler = this.handleMessage.bind(this);
    window.addEventListener("message", this.messageHandler);
  }

  disconnectedCallback() {
    window.removeEventListener("message", this.messageHandler);
  }

  handleMessage(event) {
    if (
      event.origin !== "https://www.cv-transformer.com" ||
      event.data.type !== "navigate"
    )
      return;

    this[NavigationMixin.Navigate]({
      attributes: { actionName: "view", recordId: event.data.recordId },
      type: "standard__recordPage"
    });
    getEnclosingUtilityId().then((utilityId) => minimizeUtility(utilityId));
  }
}
