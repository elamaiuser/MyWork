public class skedXMLUtils {
    private String namespace;

    public skedXMLUtils(String namespace) {
        this.namespace = namespace;
    }

    public Dom.XmlNode getResponseBody(DOM.Document docx) {
        DOM.XMLNode xroot = docx.getRootElement();
        DOM.XMLNode xbody = xroot.getChildElements()[0];
        return xbody.getChildElements()[0];
    }

    public List<Dom.XmlNode> getChildNodes(Dom.XmlNode node, String key) {
        List<Dom.XmlNode> nodes = new List<Dom.XmlNode>();

        while (hasChildNode(node, key)) {
            Dom.XmlNode child = node.getChildElement(key, this.namespace);
            nodes.add(child);
            node.removeChild(child);
        }

        return nodes;
    }

    public Dom.XmlNode getChild(Dom.XmlNode node, String key) {
        return node.getChildElement(key, this.namespace);
    }

    public String getAttribute(Dom.XmlNode node, String key) {
        return node.getAttribute(key, this.namespace);
    }

    public Boolean hasChildNode(Dom.XmlNode node, String key) {
        Boolean hasChild = false;

        for (Dom.XmlNode child : node.getChildren()) {
            if (child.getName() == key) {
                hasChild = true;
                break;
            }
        }

        return hasChild;
    }

    public String getInnerText(Dom.XmlNode node, String key) {
        return getChild(node, key).getText();
    }
}